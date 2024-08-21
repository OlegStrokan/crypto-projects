// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract DAO {
    string[] public descriptions;
    uint256[] public amounts;
    address[] public recipients;

    uint256 public contributionTimeEnd;
    uint256 public voteTime;
    uint256 public quorum;
    uint256[] public createTimes;
    uint256 public daoBalance;

    address[] public investorList;
    mapping(address => bool) public addrState;
    mapping(address => uint256) public balance;
    mapping(address => mapping(uint256 => bool)) public voteState;
    mapping(uint256 => uint256) public voteNum;

    address public owner;

    // Custom errors
    error NotOwner();
    error ContributionPeriodEnded();
    error InsufficientContributionAmount();
    error InsufficientBalanceForRedemption();
    error InsufficientBalanceForTransfer();
    error TransferAmountZero();
    error TransferToSelf();
    error ProposalCreationFailed();
    error VotingPeriodEnded();
    error VotingPeriodNotEnded();
    error AlreadyVoted();
    error NotInvestor();
    error QuorumNotMet();
    error InsufficientDAOFunds();

    event Contribution(address indexed user, uint256 amount);
    event RedeemShare(address indexed user, uint256 amount);
    event TransferShare(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event CreateProposal(string description, uint256 amount, address recipient);
    event VoteProposal(
        address indexed voter,
        uint256 indexed proposalId,
        uint256 weight
    );
    event ProposalExecuted(uint256 indexed proposalId);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function initializeDAO(
        uint256 _contributionTimeEnd,
        uint256 _voteTime,
        uint256 _quorum
    ) public onlyOwner {
        if (_contributionTimeEnd == 0 || _voteTime == 0 || _quorum == 0)
            revert ProposalCreationFailed();
        contributionTimeEnd = _contributionTimeEnd + block.timestamp;
        voteTime = _voteTime;
        quorum = _quorum;
    }

    function contribution() public payable {
        if (block.timestamp > contributionTimeEnd)
            revert ContributionPeriodEnded();
        if (msg.value == 0) revert InsufficientContributionAmount();

        if (!addrState[msg.sender]) {
            addrState[msg.sender] = true;
            investorList.push(msg.sender);
        }
        balance[msg.sender] += msg.value;
        daoBalance += msg.value;

        emit Contribution(msg.sender, msg.value);
    }

    function redeemShare(uint256 amount) public {
        if (balance[msg.sender] < amount || address(this).balance < amount)
            revert InsufficientBalanceForRedemption();

        balance[msg.sender] -= amount;
        daoBalance -= amount;
        address payable recipient = payable(msg.sender);
        recipient.transfer(amount);

        emit RedeemShare(msg.sender, amount);
    }

    function transferShare(uint256 amount, address to) public {
        if (balance[msg.sender] < amount)
            revert InsufficientBalanceForTransfer();
        if (amount == 0) revert TransferAmountZero();
        if (msg.sender == to) revert TransferToSelf();

        if (!addrState[to]) {
            addrState[to] = true;
            investorList.push(to);
        }
        balance[msg.sender] -= amount;
        balance[to] += amount;

        emit TransferShare(msg.sender, to, amount);
    }

    function createProposal(
        string calldata description,
        uint256 amount,
        address payable recipient
    ) public onlyOwner {
        if (address(this).balance < amount) revert InsufficientDAOFunds();

        descriptions.push(description);
        amounts.push(amount);
        recipients.push(recipient);
        createTimes.push(block.timestamp);

        emit CreateProposal(description, amount, recipient);
    }

    function voteProposal(uint256 proposalId) public {
        if (block.timestamp > createTimes[proposalId] + voteTime)
            revert VotingPeriodEnded();
        if (voteState[msg.sender][proposalId]) revert AlreadyVoted();
        if (!addrState[msg.sender]) revert NotInvestor();

        voteState[msg.sender][proposalId] = true;
        voteNum[proposalId] += balance[msg.sender];

        emit VoteProposal(msg.sender, proposalId, balance[msg.sender]);
    }

    function executeProposal(uint256 proposalId) public onlyOwner {
        if (block.timestamp <= createTimes[proposalId] + voteTime)
            revert VotingPeriodNotEnded();
        if (voteNum[proposalId] <= (daoBalance * quorum) / 100)
            revert QuorumNotMet();
        if (amounts[proposalId] > address(this).balance)
            revert InsufficientDAOFunds();

        address payable to = payable(recipients[proposalId]);
        to.transfer(amounts[proposalId]);

        emit ProposalExecuted(proposalId);
    }

    function proposalList()
        public
        view
        returns (string[] memory, uint256[] memory, address[] memory)
    {
        require(descriptions.length > 0, "No proposals available");
        return (descriptions, amounts, recipients);
    }

    function allInvestorsList() public view returns (address[] memory) {
        require(investorList.length > 0, "No investors available");
        return investorList;
    }

    // @dev: function just for testing
    function getInvestorBalance(
        address investor
    ) public view returns (uint256) {
        return balance[investor];
    }
}
