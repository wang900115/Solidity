// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract SimpleAuction {
    address payable public beneficiary; // 得標者出現後 收款的地址
    uint public auctionEndTime;         // 拍賣結束時間

    address public highestBidder;      
    uint public highestBid;

    mapping (address => uint) pendingReturns; // 記錄 每個出價者被超越後，可以領回的金額

    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    error AuctionAlreadyEnded();
    error BidNotHighEnough(uint highestBid);
    error AuctionNotYetEnded();
    error AuctionEndAlreadyCalled();

    constructor(
        uint biddingTime,
        address payable beneficiaryAddress
    ) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    function bid() external payable {
        if (block.timestamp > auctionEndTime) 
            revert AuctionAlreadyEnded();
        
        if (msg.value <= highestBid) 
            revert BidNotHighEnough(highestBid);
        
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function authionEnd() external {
        // 檢查 -> 狀態變更 -> 外部互動
        if (block.timestamp < auctionEndTime) 
            revert AuctionNotYetEnded();
        if (ended) 
            revert AuctionEndAlreadyCalled();

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
    }
}