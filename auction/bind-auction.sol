// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    address payable public beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    mapping(address=> Bid[]) public bids;

    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) pendingReturns;

    event AuctionEnded(address winner, uint highestBid);

    error TooEarly(uint time);
    error TooLate(uint time);
    error AuctionEndAlreadyCalled();


    // modifier 為 在函數執行前/後插入檢查或是共用邏輯 _為佔位符
    modifier onlyBefore(uint time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;
    }

    modifier onlyAfter(uint time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    constructor (
        uint biddingTime,
        uint revealTime,
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        biddingEnd = block.timestamp + biddingTime;
        revealEnd = block.timestamp + revealTime;
    }

    function bid(bytes32 blindedBid) external payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(Bid({
            blindedBid: blindedBid,
            deposit: msg.value
        }));
    }
    
    function reavel(uint[] calldata values, bool[] calldata fakes, bytes32[] calldata secrets) external onlyAfter(biddingEnd) onlyBefore(revealEnd) {
        uint length = bids[msg.sender].length;
        require(values.length == length);
        require(fakes.length == length);
        require(secrets.length == length);

        uint refund;

        for (uint i = 0; i < length; i++) {
            Bid storage bidToCheck = bids[msg.sender][i];
            (uint value, bool fake, bytes32 secret) = (values[i], fakes[i], secrets[i]);

            if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value,fake,secret))) {
                continue;
            }
            refund += bidToCheck.deposit;
            // 保證金 >= 投標金額，才算是有效競標
            if (!fake && bidToCheck.deposit >= value) {
                if (placeBid(msg.sender, value)) 
                    refund -= value; // 出價成功，要扣掉真正的競標金額
            }

            bidToCheck.blindedBid = bytes32(0);
        }
        payable(msg.sender).transfer(refund);
    }

    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    function auctionEnd() external onlyAfter(revealEnd) {
        if (ended) revert AuctionEndAlreadyCalled();
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }

    function placeBid(address bidder, uint value) internal returns (bool success) {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }
}