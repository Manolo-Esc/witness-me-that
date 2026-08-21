// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract PaymentRegistry {
    struct Payment {
        string fileHash;  // Hash of the payment file (SHA-256, for example)
        string fileURL;   // Link to the file itself (IPFS, Arweave, etc.)
        uint256 timestamp;
        address payer;
    }

    mapping(address => Payment[]) public payments;

    event PaymentRegistered(address indexed payer, string fileHash, string fileURL, uint256 timestamp);

    function registerPayment(string memory _fileHash, string memory _fileURL) public {
        require(bytes(_fileHash).length > 0, "File hash cannot be empty");
        require(bytes(_fileURL).length > 0, "File URL cannot be empty");

        payments[msg.sender].push(Payment(_fileHash, _fileURL, block.timestamp, msg.sender));

        emit PaymentRegistered(msg.sender, _fileHash, _fileURL, block.timestamp);
    }

    function getPayments(address _payer) public view returns (Payment[] memory) {
        return payments[_payer];
    }
}
