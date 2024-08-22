// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DAO {
    string[] descriptions;
    uint[] amounts;
    address[] receipients;

    uint256 contributionTimeEnd;
    uint256 voteTime;
    uint256 quorum;
    uint256[] createTimes;
    uint256 daoBalance;

    address[] investorList;
    mapping(address => bool) addrState; // true:You are in the List
    mapping(address => uint256) balance;
    mapping(address => mapping(uint256 => bool)) voteState;
    mapping(uint256 => uint256) voteNum;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function initializeDAO(
        uint256 _contributionTimeEnd,
        uint256 _voteTime,
        uint256 _quorum
    ) public onlyOwner {
        require(_contributionTimeEnd > 0 && _voteTime > 0 && _quorum > 0);
        contributionTimeEnd = _contributionTimeEnd + block.timestamp;
        voteTime = _voteTime;
        quorum = _quorum;
    }

    function contribution() public payable {
        require(block.timestamp <= contributionTimeEnd);
        require(msg.value > 0);
        if (addrState[msg.sender] == false) {
            addrState[msg.sender] = true;
            investorList.push(msg.sender);
        }
        balance[msg.sender] = balance[msg.sender] + msg.value;
        daoBalance = daoBalance + msg.value;
    }

    function redeemShare(uint256 amount) public {
        require(
            balance[msg.sender] >= amount && address(this).balance >= amount
        );
        balance[msg.sender] = balance[msg.sender] - amount;
        daoBalance = daoBalance - amount;
        address payable receipient = payable(msg.sender);
        receipient.transfer(amount);
    }

    function transferShare(uint256 amount, address to) public {
        require(balance[msg.sender] >= amount && amount > 0);
        if (addrState[to] == false) {
            addrState[to] = true;
            investorList.push(to);
        }
        balance[msg.sender] = balance[msg.sender] - amount;
        balance[to] = balance[to] + amount;
    }

    function createProposal(
        string calldata description,
        uint256 amount,
        address payable receipient
    ) public onlyOwner {
        require(address(this).balance >= amount);
        descriptions.push(description);
        amounts.push(amount);
        receipients.push(receipient);
        createTimes.push(block.timestamp);
    }

    function voteProposal(uint256 proposalId) public {
        require(block.timestamp <= createTimes[proposalId] + voteTime);
        require(voteState[msg.sender][proposalId] == false);
        require(addrState[msg.sender] == true);
        voteState[msg.sender][proposalId] = true;
        voteNum[proposalId] = voteNum[proposalId] + balance[msg.sender];
    }

    function executeProposal(uint256 proposalId) public onlyOwner {
        // require(block.timestamp > createTimes[proposalId] + voteTime);
        // require(voteNum[proposalId] > daoBalance*quorum/100);
        // require(amounts[proposalId] >= address(this).balance);
        address payable to = payable(receipients[proposalId]);
        to.transfer(amounts[proposalId]);
    }

    function proposalList()
        public
        view
        returns (string[] memory, uint[] memory, address[] memory)
    {
        require(descriptions.length >= 1);
        return (descriptions, amounts, receipients);
    }

    function allInvestorList() public view returns (address[] memory) {
        require(investorList.length >= 1);
        return investorList;
    }
}
