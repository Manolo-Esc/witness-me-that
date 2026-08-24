// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title PaymentRegistry
/// @notice Immutable registry of payment receipts: each user stores the hash and the URL
///         of the file that proves a payment, together with the time it was registered.
contract PaymentRegistry {
    /// @dev A `struct` is a compound type (like a record/object). It only defines the
    ///      shape of each registry entry; by itself it reserves no storage.
    struct Payment {
        string fileHash;  // Hash of the payment file (SHA-256, for example)
        string fileURL;   // Link to the file itself (IPFS, Arweave, etc.)
        uint256 timestamp;
        address payer;
    }

    /// @dev `mapping(key => value)` is a hash table held in on-chain storage. Here it
    ///      associates every address with its own array of payments. A mapping cannot be
    ///      iterated and has no length: it can only be queried key by key.
    ///      Declaring it `public` makes Solidity generate an automatic getter
    ///      `payments(address, uint256)`: you must pass both the address AND the array
    ///      index, and it returns the fields of that single Payment. That is why
    ///      `getPayments` exists, to return the whole array in one call.
    ///      Querying an address with no payments does not fail: it returns an empty array.
    mapping(address => Payment[]) public payments;

    /// @dev An `event` writes data into the transaction log (far cheaper than storage).
    ///      It cannot be read by another contract, but it can be read off-chain: a client
    ///      (ethers.js, web3.py, The Graph...) can subscribe to these events or query
    ///      past ones.
    ///      `indexed` turns the parameter into a log "topic", which allows filtering by it
    ///      (e.g. "give me every payment from this address") without scanning every log.
    ///      Solidity allows up to 3 `indexed` parameters per event.
    event PaymentRegistered(address indexed payer, string fileHash, string fileURL, uint256 timestamp);

    /// @notice Registers a new payment receipt on behalf of the caller.
    /// @dev State-changing function: it requires a signed transaction and costs gas.
    /// @param _fileHash Hash of the receipt file.
    /// @param _fileURL  URL where the file is hosted.
    // `string memory`: variable-length types need an explicit data location.
    // `memory` = temporary copy that only lives for the duration of this call (the
    // alternative, `calldata`, would be read-only and slightly cheaper).
    // `public` = callable off-chain and also from within this contract.
    function registerPayment(string memory _fileHash, string memory _fileURL) public {
        // `require(condition, message)`: if the condition is false it reverts the whole
        // transaction (every state change is rolled back), refunds the unused gas and
        // propagates the error message back to the caller.
        // `bytes(_fileHash)` converts the string into its raw byte array so that
        // `.length` can be read: Solidity `string` has no `.length` member of its own.
        // Note it measures UTF-8 bytes, not characters. Here it is only used to detect an
        // empty string.
        require(bytes(_fileHash).length > 0, "File hash cannot be empty");
        require(bytes(_fileURL).length > 0, "File URL cannot be empty");

        // `payments[msg.sender]` accesses (or implicitly creates) the caller's array.
        // `.push(...)` appends an element to a storage dynamic array; it is only available
        // for dynamic arrays living in storage.
        // `msg.sender` is the address that originated this call: the guarantee that nobody
        // can register payments on someone else's behalf (there is no author parameter).
        // `block.timestamp` is the timestamp (Unix seconds) of the block including this
        // transaction. It is set by the validator, so it is approximate and slightly
        // manipulable (a few seconds of slack); use it as a time stamp, not as an exact
        // clock.
        payments[msg.sender].push(Payment(_fileHash, _fileURL, block.timestamp, msg.sender));

        // `emit` fires the event and writes it into the transaction log. This is what
        // lets a backend or a frontend react to the registration without continuously
        // polling the contract state.
        emit PaymentRegistered(msg.sender, _fileHash, _fileURL, block.timestamp);
    }

    /// @notice Returns every payment registered by an address.
    /// @dev `view` = reads state only, never modifies it. Called off-chain (`eth_call`) it
    ///      creates no transaction and is free; if another contract called it inside a
    ///      transaction, the storage reads would cost gas.
    ///      `returns (Payment[] memory)`: a copy of the array of structs is returned in
    ///      memory (a storage reference cannot be returned to the outside world).
    ///      Warning: the cost grows with the number of payments; with very large arrays
    ///      the call can hit the node's gas limit.
    function getPayments(address _payer) public view returns (Payment[] memory) {
        return payments[_payer];
    }

    /// @notice Returns how many payments are filed under an address.
    /// @dev Needed for pagination: the auto-generated `payments(address, uint256)` getter
    ///      gives no way to discover the array length from off-chain, and an out-of-range
    ///      index simply reverts. Callers use this to know how many pages to ask for.
    function getPaymentsCount(address _payer) public view returns (uint256) {
        return payments[_payer].length;
    }

    /// @notice Returns at most `_limit` payments of `_payer`, starting at index `_offset`.
    /// @dev Bounded alternative to `getPayments`: the work and the returned data grow with
    ///      the page size, not with the whole array.
    /// @param _offset Index of the first payment to return (0 = oldest registered).
    /// @param _limit  Maximum number of payments to return; the last page may be shorter.
    /// @return page Payments in registration order. Empty if `_offset` is past the end.
    function getPaymentsPaged(address _payer, uint256 _offset, uint256 _limit)
        public
        view
        returns (Payment[] memory page)
    {
        // `storage` keeps a reference to the on-chain array instead of copying it into
        // memory; only the elements of the requested page are copied below.
        Payment[] storage all = payments[_payer];

        // An offset past the end is not an error: returning an empty page lets a client
        // keep requesting pages until it gets fewer than `_limit` items back.
        // `new Payment[](n)` allocates a fixed-size array in memory: unlike a storage
        // array it has no `push`, so its length must be known up front.
        if (_offset >= all.length) {
            return new Payment[](0);
        }

        // Clamp the window to the array length so the last page is truncated instead of
        // reverting. Comparing against the remaining count rather than computing
        // `_offset + _limit` also avoids an overflow revert on an absurdly large `_limit`,
        // which is then simply read as "give me the rest".
        uint256 remaining = all.length - _offset;
        uint256 end = _limit < remaining ? _offset + _limit : all.length;

        page = new Payment[](end - _offset);
        for (uint256 i = _offset; i < end; i++) {
            // Each assignment copies one struct (including its two strings) from storage
            // into memory. This is the only part of the cost that scales with the page.
            page[i - _offset] = all[i];
        }
    }
}
