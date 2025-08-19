// SPDX-License-Identifier: GPL-3.0 
pragma solidity ^0.8.26;

contract Coin {

    address public minter;
    mapping (address => uint)  public balances;
    // event allow clients to react to specific contract change you declare
    event Sent(address from, address to, uint amount);

    constructor() {
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver]+=amount;
    }

    error InsufficientBalance(uint requested, uint available);

    function send(address receiver, uint amount) public {
        require(amount <= balances[msg.sender], InsufficientBalance(amount, balances[msg.sender]));
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }

}

