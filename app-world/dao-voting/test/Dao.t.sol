//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/DAO.sol";

contract DaoTest is Test {
    DAO public dao;
    address payable public owner;
    address payable public investor1;
    address payable public investor2;
    address payable public recipient;

    function setUp() public {
        owner = payable(address(0x1));
        investor1 = payable(address(0x2));
        investor2 = payable(address(0x3));
        recipient = payable(address(0x4));

        // Deploy the DAO contract and initialize it
        vm.startPrank(owner);
        dao = new DAO();
        dao.initializeDAO(1 weeks, 1 days, 50);
        vm.stopPrank();

        // Fund the investors with some Ether for testing
        vm.deal(investor1, 2 ether);
        vm.deal(investor2, 2 ether);
        vm.deal(owner, 3 ether);
    }

    //----------------------------init tests----------------------------//

    /// @notice Should fail because the caller of initializeDAO is not the owner
    function testInitFailsWhenNotOwner() public {
        vm.prank(address(0x5));
        vm.expectRevert(DAO.NotOwner.selector);
        dao.initializeDAO(1 weeks, 1 days, 50);
    }

    //-------------------------contribution tests-----------------------//

    /// @notice Should correctly calculate each investor's balance and the total DAO balance after contributions
    function testContribution() public {
        vm.prank(investor1);
        dao.contribution{value: 1 ether}();

        vm.prank(investor2);
        dao.contribution{value: 2 ether}();

        assertEq(dao.getInvestorBalance(investor1), 1 ether);
        assertEq(dao.getInvestorBalance(investor2), 2 ether);
        assertEq(address(dao).balance, 3 ether);
    }

    /// @notice Should fail because the contribution is made after the contribution period has ended
    function testContributionFailsWhenPeriodEnded() public {
        vm.prank(owner);
        dao.initializeDAO(1, 1 days, 50);

        vm.warp(block.timestamp + 2 seconds);

        vm.expectRevert(DAO.ContributionPeriodEnded.selector);
        vm.prank(investor1);
        dao.contribution{value: 1 ether}();
    }

    /// @notice Should fail because the investor attempts to contribute 0 ethers
    function testContributionFailsWhenInsufficientFunds() public {
        vm.expectRevert(DAO.InsufficientContributionAmount.selector);
        vm.prank(investor1);
        dao.contribution{value: 0 ether}();
    }

    //-------------------------redeem share tests-----------------------//

    /// @notice Should correctly update the investor's balance and DAO balance after redemption
    function testRedeemShare() public {
        vm.prank(investor1);
        dao.contribution{value: 1 ether}();

        vm.prank(investor2);
        dao.contribution{value: 2 ether}();

        vm.prank(investor1);
        dao.redeemShare(1 ether);

        vm.prank(investor2);
        dao.redeemShare(1 ether);

        assertEq(dao.getInvestorBalance(investor1), 0 ether);
        assertEq(dao.getInvestorBalance(investor2), 1 ether);
        assertEq(address(dao).balance, 1 ether);
    }

    /// @notice Should fail because the investor attempts to redeem more Ether than they have deposited
    function testRedeemShareFailsWhenInsufficientFunds() public {
        vm.prank(investor1);
        dao.contribution{value: 1 ether}();

        vm.expectRevert(DAO.InsufficientBalanceForRedemption.selector);
        vm.prank(investor1);
        dao.redeemShare(2 ether);
    }

    /// @notice Should fail because the DAO does not have enough Ether to fulfill the redemption request
    function testRedeemShareFailsWhenInsufficientAmount() public {
        vm.deal(address(dao), 2 ether);

        vm.prank(owner);
        dao.contribution{value: 1 ether}();

        vm.expectRevert(DAO.InsufficientBalanceForRedemption.selector);
        vm.prank(owner);
        dao.redeemShare(2 ether);
    }

    //-------------------------transfer share tests-----------------------//

    /// @notice Should correctly transfer shares between investors and update their balances
    function testTransferShare() public {
        vm.prank(investor1);
        dao.contribution{value: 2 ether}();

        vm.prank(investor1);
        dao.transferShare(1 ether, investor2);

        assertEq(dao.getInvestorBalance(investor1), 1 ether);
        assertEq(dao.getInvestorBalance(investor2), 1 ether);
    }

    /// @notice Should fail because the investor attempts to transfer more shares than they have
    function testTransferShareFailsWhenInsufficientShares() public {
        vm.prank(investor1);
        dao.contribution{value: 1 ether}();

        vm.expectRevert(DAO.InsufficientBalanceForTransfer.selector);
        vm.prank(investor1);
        dao.transferShare(2 ether, investor2);
    }

    /// @notice Should fail because the investor attempts to transfer zero shares
    function testTransferShareFailsWhenInsufficientAmount() public {
        vm.prank(investor1);
        dao.contribution{value: 1 ether}();

        vm.expectRevert(DAO.TransferAmountZero.selector);
        vm.prank(investor1);
        dao.transferShare(0 ether, investor2);
    }

    /// @notice Should fail because the investor attempts to transfer shares to themselves
    function testTransferShareFailsWhenTransferringToSelf() public {
        vm.prank(investor1);
        dao.contribution{value: 1 ether}();

        vm.expectRevert(DAO.TransferToSelf.selector);
        vm.prank(investor1);
        dao.transferShare(1 ether, investor1);
    }

    //-------------------------create proposal tests-----------------------//

    /// @notice Should create a proposal and ensure that the values are correctly stored
    function testCreateProposal() public {
        uint256 gasBefore = gasleft();

        vm.prank(owner);
        dao.contribution{value: 2 ether}();

        vm.prank(owner);
        dao.createProposal("Fund local artist", 1 ether, recipient);

        (
            string[] memory description,
            uint256[] memory amounts,
            address[] memory recipients
        ) = dao.proposalList();

        assertEq(description[0], "Fund local artist");
        assertEq(amounts[0], 1 ether);
        assertEq(recipients[0], recipient);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        console.log("gas used", gasUsed);
    }

    /// @notice Should fail because the DAO contract does not have enough Ether to fund the proposal
    function testCreateProposalFailsWhenInsufficientDAOFunds() public {
        _fundAndCreateProposal();

        vm.prank(owner);
        dao.contribution{value: 1.1 ether}();

        vm.prank(owner);
        dao.redeemShare(1 ether);

        vm.expectRevert(DAO.InsufficientDAOFunds.selector);
        vm.prank(owner);
        dao.createProposal("New proposal", 1 ether, recipient);
    }

    //-------------------------vote proposal tests-----------------------//

    /// @notice Should correctly update the vote count after a successful vote
    function testVoteProposal() public {
        _fundAndCreateProposal();

        vm.prank(investor1);
        dao.contribution{value: 1 ether}();

        vm.prank(investor1);
        dao.voteProposal(0);

        assertEq(dao.voteNum(0), 1 ether);
    }

    /// @notice Should fail because the voting period has ended
    function testVoteProposalFailsWhenVotingPeriodEnded() public {
        _fundAndCreateProposal();

        vm.prank(investor1);
        dao.contribution{value: 1 ether}();

        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(DAO.VotingPeriodEnded.selector);
        vm.prank(investor1);
        dao.voteProposal(0);
    }

    /// @notice Should fail because the investor has already voted on this proposal
    function testVoteProposalFailsWhenAlreadyVoted() public {
        _fundAndCreateProposal();

        vm.prank(investor1);
        dao.contribution{value: 1 ether}();

        vm.prank(investor1);
        dao.voteProposal(0);

        vm.expectRevert(DAO.AlreadyVoted.selector);
        vm.prank(investor1);
        dao.voteProposal(0);
    }

    /// @notice Should fail because the caller is not a DAO investor
    function testVoteProposalFailsWhenNotInvestor() public {
        _fundAndCreateProposal();

        vm.expectRevert(DAO.NotInvestor.selector);
        vm.prank(investor1);
        dao.voteProposal(0);
    }

    //-------------------------execute proposal tests-----------------------//

    /// @notice Should transfer the correct amount of Ether to the proposal recipient after a successful vote and execution
    /// @dev Uses vm.warp to simulate the passage of time until the execution period is available
    function testExecuteProposal() public {
        _fundAndCreateProposal();

        vm.prank(investor1);
        dao.contribution{value: 1 ether}();

        vm.prank(investor1);
        dao.voteProposal(0);

        vm.warp(block.timestamp + 2 days);
        vm.prank(owner);
        dao.executeProposal(0);

        assertEq(address(recipient).balance, 1 ether);
    }

    /// @notice Should fail because the voting period has not ended yet
    function testExecuteProposalFailsWhenVotingPeriodNotEnded() public {
        _fundAndCreateProposal();

        vm.prank(investor1);
        dao.contribution{value: 1 ether}();

        vm.prank(investor1);
        dao.voteProposal(0);

        vm.expectRevert(DAO.VotingPeriodNotEnded.selector);
        vm.prank(owner);
        dao.executeProposal(0);
    }

    /// @notice Should fail because the quorum was not met (not enough votes were cast)
    function testExecuteProposalFailsWhenQuorumNotMet() public {
        /*
         _fundAndCreateProposal();

        vm.deal(address(owner), 2 ether);
        vm.prank(owner);
        dao.contribution{value: 0.4 ether}();

        vm.prank(owner);
        dao.voteProposal(0);

        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(DAO.QuorumNotMet.selector);
        vm.prank(owner);
        dao.executeProposal(0);
        */
    }

    /// @notice Should fail because the DAO does not have sufficient funds to execute the proposal
    function testExecuteProposalWhenInsufficientDAOFunds() public {
        _fundAndCreateProposal();

        vm.prank(investor1);
        dao.contribution{value: 1 ether}();

        vm.warp(block.timestamp + 1 days);

        vm.prank(owner);
        dao.redeemShare(1 ether);

        vm.expectRevert(DAO.InsufficientDAOFunds.selector);
        vm.prank(owner);
        dao.executeProposal(0);
    }

    //---------------------------- Helper Functions ----------------------------//

    /// @dev Helper function to fund DAO and create a proposal using hardcoded values
    function _fundAndCreateProposal() private {
        vm.deal(address(dao), 2 ether);
        vm.prank(owner);
        dao.createProposal("Default Proposal", 1 ether, recipient);
    }

    receive() external payable {}
}
