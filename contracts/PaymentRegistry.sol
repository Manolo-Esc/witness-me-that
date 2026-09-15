// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title PaymentRegistry
/// @notice Immutable registry of payment receipts: each user stores the hash and the URL
///         of the file that proves a payment, together with the time it was registered.
contract PaymentRegistry {
    // This only defines the shape of each registry entry. It reserves no storage.
    struct Payment {
        string fileHash;  // Hash of the payment file (SHA-256, for example)
        string fileURL;   // Link to the file itself 
        uint256 timestamp;
        address payer;
    }

    /// @dev `mapping(key => value)` is a hash table held in on-chain storage. Here it
    ///      associates every address with its own array of payments. A mapping cannot be
    ///      iterated and has no length: it can only be queried key by key.
    ///      You can think of the contract’s state as its persistent data. It lives in 
    ///      `storage`, persists after a function finishes executing, and is stored on the 
    ///      blockchain. Any changes to state variables are recorded on-chain.
    mapping(address => Payment[]) public payments;

    /// @dev An `event` writes data into the transaction log. It cannot be read by 
    ///      another contract, but it can be read off-chain: a client can subscribe 
    ///      to these events or query past ones.
    ///      `indexed` turns the parameter into a log "topic", which allows filtering by it
    event PaymentRegistered(address indexed payer, string fileHash, string fileURL, uint256 timestamp);

    /// @notice Registers a new payment receipt on behalf of the caller.
    /// @dev State-changing function (modifies `payments`): it requires a signed transaction and costs gas.
    /// @param _fileHash Hash of the receipt file.
    /// @param _fileURL  URL where the file is hosted.
    // `string memory`: variable-length types need an explicit data location.
    // `memory` = temporary copy that only lives for the duration of this call
    // `public` = callable off-chain and also from within this contract.
    function registerPayment(string memory _fileHash, string memory _fileURL) public {
        require(bytes(_fileHash).length > 0, "File hash cannot be empty");
        require(bytes(_fileURL).length > 0, "File URL cannot be empty");

        // `payments[msg.sender]` accesses (or implicitly creates) the caller's array.
        // `msg.sender` is the address that originated this call
        payments[msg.sender].push(Payment(_fileHash, _fileURL, block.timestamp, msg.sender));

        // `emit` fires the event and writes it into the transaction log
        emit PaymentRegistered(msg.sender, _fileHash, _fileURL, block.timestamp);
    }

    /// @notice Returns every payment registered by an address.
    /// @dev `view` = reads state only, never modifies it. When called off-chain it
    ///      creates no transaction and is free. If another contract called it inside a
    ///      transaction, the storage reads would cost gas.
    ///      `returns (Payment[] memory)`: a copy of the array of structs is returned
    ///      Warning: the cost grows with the number of payments; with very large arrays
    ///      the call can hit the node's gas limit.
    function getPayments(address _payer) public view returns (Payment[] memory) {
        return payments[_payer];
    }

    /// @notice Returns how many payments are filed under an address.
    /// @dev Needed for pagination
    function getPaymentsCount(address _payer) public view returns (uint256) {
        return payments[_payer].length;
    }

    /// @notice Returns at most `_limit` payments of `_payer`, starting at index `_offset`.
    /// @dev Bounded alternative to `getPayments`
    /// @param _offset Index of the first payment to return (0 = oldest registered).
    /// @param _limit  Maximum number of payments to return; the last page may be shorter.
    /// @return page Payments in registration order. Empty if `_offset` is past the end.
    function getPaymentsPaged(address _payer, uint256 _offset, uint256 _limit) public view returns (Payment[] memory page) {
        // `storage` keeps a reference to the on-chain array instead of copying it into memory
        Payment[] storage all = payments[_payer];

        // `new Payment[](n)` allocates a fixed-size array in memory
        if (_offset >= all.length) {
            return new Payment[](0);
        }

        uint256 remaining = all.length - _offset;
        uint256 end = _limit < remaining ? _offset + _limit : all.length;

        page = new Payment[](end - _offset);
        for (uint256 i = _offset; i < end; i++) {
            // Each assignment copies one struct (including its two strings) from storage into memory
            page[i - _offset] = all[i];
        }
    }
}
