// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0 <0.9.0;

contract Ballot {
// Voter: 紀錄一個投票者的紀錄
    struct Voter {
        uint weight; // 投票權重
        bool voted; // 是否已經投票
        address delegate; // 委託給誰
        uint vote;          // 投票給哪個提議
    }
// Proposal: 紀錄一個提案的狀態
    struct Proposal {
        bytes32 name; // 提案名稱 
        uint voteCount; // 累積票數
    }

    address public chairperson; // 主席 (擁有分配投票權的權利)

    mapping(address => Voter) public voters;
    Proposal[] public proposals; // 所有提案


    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1; // 部署合約的人是主席，並且自動獲得一票

        for (uint i=0; i < proposalNames.length;i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function giveRightToVote(address voter) external {
        // 如果是false則會回滾 (revert) 所有狀態改變（例如變數更新、ETH 轉帳）。
        /*
            1.傳入參數是否合法
            2.呼叫者是否有權限
            3.餘額是否足夠
        */
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );

        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight==0);
        voters[voter].weight = 1;
    }

    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no right to vote");
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");
        // 避免委託鏈中出現迴圈
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation.");
        }

        Voter storage delegate_ = voters[to];
        require(delegate_.weight >= 1);

        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }

    }

    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote.");
        require(!sender.voted,"Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        proposals[proposal].voteCount += sender.weight;
    }


    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}
// view 
/*
    1. 只讀取鏈上狀態
    2. 不消耗 Gas
*/

// pure 
/*
    1. 不讀取或不修改鏈上狀態
*/

// payable
/*
    1. 接收 Ether
*/

// nonpayable
/*
    1. 不能收 Ether
*/

