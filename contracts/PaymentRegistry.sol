// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract PaymentRegistry {
    struct Payment {
        string fileHash;  // Hash del archivo de pago (SHA-256, por ejemplo)
        string fileURL;   // Enlace al archivo (IPFS, Arweave, etc.)
        uint256 timestamp;
        address payer;
    }

    mapping(address => Payment[]) public payments;

    event PaymentRegistered(address indexed payer, string fileHash, string fileURL, uint256 timestamp);

    function registerPayment(string memory _fileHash, string memory _fileURL) public {
        require(bytes(_fileHash).length > 0, unicode"El hash del archivo no puede estar vacío");
        require(bytes(_fileURL).length > 0, unicode"El URL del archivo no puede estar vacío");

        payments[msg.sender].push(Payment(_fileHash, _fileURL, block.timestamp, msg.sender));

        emit PaymentRegistered(msg.sender, _fileHash, _fileURL, block.timestamp);
    }

    function getPayments(address _payer) public view returns (Payment[] memory) {
        return payments[_payer];
    }
}
