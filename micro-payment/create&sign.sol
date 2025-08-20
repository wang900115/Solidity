// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Owned {
    address payable owner;
    constructor() {
        owner = payable(msg.sender);
    }
}

contract Freezable is Owned {
    bool private _frozen = false;

    modifier notFrozen() {
        require(!_frozen, "Inactive Contract.");
        _;
    }

    function freeze() internal {
        if (msg.sender == owner) 
            _frozen = true;
    }
}

contract ReceiverPays is Freezable {
    mapping(uint256 => bool) usedNonces;

    constructor() payable {}

    function claimPayment(uint256 amount, uint nonce, bytes memory signature) external notFrozen {
        require(!usedNonces[nonce]);
        usedNonces[nonce] = true;
        // recreate message that was signed on the client
        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, amount, nonce, this)));
        require(recoverSigner(message, signature) == owner);
        payable(msg.sender).transfer(amount);
    }

    function shutdown() external notFrozen {
        require(msg.sender == owner);
        freeze();
        payable(msg.sender).transfer(address(this).balance);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);

        assembly {
            r := mload(add(sig,32))
            s := mload(add(sig,64))
            v := byte(0, mload(add(sig,96)))
        }

        return (v, r, s);
    } 

    // r (32 bytes) | s (32 bytes) | v (1 byte)

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hash));
    }

    
}