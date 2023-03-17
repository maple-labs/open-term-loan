// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { console2, Test } from "../modules/forge-std/src/Test.sol";

import { MapleRefinancer } from "../contracts/MapleRefinancer.sol";

import { Utils }            from "./utils/Utils.sol";
import { MapleLoanHarness } from "./utils/Harnesses.sol";

import {
    MockERC20,
    MockFactory,
    MockGlobals,
    MockLender,
    MockRevertingERC20,
    MockRevertingRefinancer
} from "./utils/Mocks.sol";

contract AcceptNewTermsFailure is Test, Utils {

    address borrower = makeAddr("borrower");

    MapleLoanHarness loan       = new MapleLoanHarness();
    MapleRefinancer  refinancer = new MapleRefinancer();
    MockGlobals      globals    = new MockGlobals();

    function setUp() external virtual {
        MockFactory mockFactory = new MockFactory();

        mockFactory.__setGlobals(address(globals));

        loan.__setFactory(address(mockFactory));
        loan.__setBorrower(borrower);
    }

    function test_acceptNewTerms_protocolPaused() external {
        globals.__setProtocolPaused(true);

        vm.expectRevert("ML:PROTOCOL_PAUSED");
        loan.acceptNewTerms(address(refinancer), block.timestamp, new bytes[](0));
    }

    function test_acceptNewTerms_notBorrower() external {
        vm.expectRevert("ML:ANT:NOT_BORROWER");
        loan.acceptNewTerms(address(refinancer), block.timestamp, new bytes[](0));
    }

    function test_acceptNewTerms_mismatchedCommitment() external {
        vm.expectRevert("ML:ANT:COMMITMENT_MISMATCH");
        vm.prank(borrower);
        loan.acceptNewTerms(address(refinancer), block.timestamp, new bytes[](0));
    }

    function test_acceptNewTerms_invalidRefinancer() external {
        loan.__setRefinanceCommitment(keccak256(abi.encode(address(0), block.timestamp, new bytes[](0))));

        vm.expectRevert("ML:ANT:INVALID_REFINANCER");
        vm.prank(borrower);
        loan.acceptNewTerms(address(0), block.timestamp, new bytes[](0));
    }

    function test_acceptNewTerms_expiredCommitmentBoundary() external {
        // Necessary to avoid revert in fundsAsset transfer
        address asset  = address(new MockERC20("Asset", "A", 6));
        address lender = address(new MockLender());

        loan.__setFundsAsset(asset);
        loan.__setLender(lender);

        loan.__setRefinanceCommitment(keccak256(abi.encode(address(refinancer), block.timestamp - 1, new bytes[](0))));

        vm.expectRevert("ML:ANT:EXPIRED_COMMITMENT");
        vm.prank(borrower);
        loan.acceptNewTerms(address(refinancer), block.timestamp - 1, new bytes[](0));

        loan.__setRefinanceCommitment(keccak256(abi.encode(address(refinancer), block.timestamp, new bytes[](0))));

        vm.prank(borrower);
        loan.acceptNewTerms(address(refinancer), block.timestamp, new bytes[](0));
    }

    function test_acceptNewTerms_refinancerRevert() external {
        address revertingRefinancer = address(new MockRevertingRefinancer());

        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encode("revertingFunction()");

        loan.__setRefinanceCommitment(keccak256(abi.encode(revertingRefinancer, block.timestamp, calls)));

        vm.expectRevert("ML:ANT:FAILED");
        vm.prank(borrower);
        loan.acceptNewTerms(revertingRefinancer, block.timestamp, calls);
    }

    function test_acceptNewTerms_transferRevert() external {
        address asset = address(new MockRevertingERC20("Asset", "A", 6));

        loan.__setFundsAsset(asset);

        loan.__setRefinanceCommitment(keccak256(abi.encode(address(refinancer), block.timestamp, new bytes[](0))));

        vm.expectRevert("ML:ANT:TRANSFER_FAILED");
        vm.prank(borrower);
        loan.acceptNewTerms(address(refinancer), block.timestamp, new bytes[](0));
    }

}

// TODO: This tests focuses on the acceptNewTerms function and it's state changes,
// it's necessary to add tests for the refinancer's state changes.
contract AcceptNewTerms is Test, Utils {

    uint256 constant gracePeriod  = 1 days;
    uint256 constant noticePeriod = 2 days;
    uint256 constant interval     = 1_000_000;

    uint256 constant interestRate            = 0.10e18;
    uint256 constant lateFeeRate             = 0.01e18;
    uint256 constant lateInterestPremiumRate = 0.05e18;
    uint256 constant principal               = 1_000_000e6;
    uint256 constant principalDiff           = 100_000e6;

    address borrower = makeAddr("borrower");

    uint256 start;

    MapleLoanHarness loan       = new MapleLoanHarness();
    MapleRefinancer  refinancer = new MapleRefinancer();
    MockGlobals      globals    = new MockGlobals();
    MockERC20        asset      = new MockERC20("Asset", "A", 6);
    MockLender       lender     = new MockLender();

    function setUp() external virtual {
        start = block.timestamp;

        MockFactory mockFactory = new MockFactory();

        mockFactory.__setGlobals(address(globals));

        loan.__setBorrower(borrower);
        loan.__setFactory(address(mockFactory));
        loan.__setFundsAsset(address(asset));
        loan.__setInterestRate(interestRate);
        loan.__setLateFeeRate(lateFeeRate);
        loan.__setLateInterestPremiumRate(lateInterestPremiumRate);
        loan.__setLender(address(lender));
        loan.__setPaymentInterval(interval);
        loan.__setPrincipal(principal);
        loan.__setDateFunded(start);

        // Setting both to a date in the future to ensure value is removed without affecting due dates.
        loan.__setDateCalled(start + 1_200_000);
        loan.__setDateImpaired(start + 1_200_000);

        vm.prank(borrower);
        asset.approve(address(loan), type(uint256).max);

        vm.prank(address(lender));
        asset.approve(address(loan), type(uint256).max);
    }

    function test_acceptNewTerms_earlyRefinance() external {
        // Warp to exactly the payment due date
        vm.warp(start + (interval / 2));

        bytes[] memory calls = _encodeCall(abi.encodeWithSignature("setPaymentInterval(uint32)", 2_000_000));

        loan.__setRefinanceCommitment(keccak256(abi.encode(address(refinancer), block.timestamp, calls)));

        loan.__setCalledPrincipal(principal);

        assertEq(loan.calledPrincipal(), principal);
        assertEq(loan.dateCalled(),      start + 1_200_000);
        assertEq(loan.dateImpaired(),    start + 1_200_000);
        assertEq(loan.datePaid(),        0);
        assertEq(loan.paymentInterval(), 1_000_000);
        assertEq(loan.paymentDueDate(),  start + interval);

        (
            ,
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        ) = loan.paymentBreakdown(block.timestamp);

        // Mint the borrower the partial payments
        asset.mint(borrower, interest_ + lateInterest_ + delegateServiceFee_ + platformServiceFee_);

        // Set up the mock lender to expect it's `claim` to be called with these specific values.
        lender.__expectCall();
        lender.claim(int256(0), interest_ + lateInterest_, delegateServiceFee_,platformServiceFee_, uint40(block.timestamp + 2_000_000));

        vm.prank(borrower);
        loan.acceptNewTerms(address(refinancer), block.timestamp, calls);

        assertEq(loan.calledPrincipal(), 0);
        assertEq(loan.dateCalled(),      0);
        assertEq(loan.dateImpaired(),    0);
        assertEq(loan.datePaid(),        start + (interval / 2));
        assertEq(loan.paymentDueDate(),  start + (interval / 2) + 2_000_000);
        assertEq(loan.paymentInterval(), 2_000_000);
    }

    function test_acceptNewTerms_principalIncrease() external {
        // Warp to exactly the payment due date
        vm.warp(start + (interval / 2));

        bytes[] memory calls = _encodeCall(abi.encodeWithSignature("increasePrincipal(uint256)", principalDiff));

        loan.__setRefinanceCommitment(keccak256(abi.encode(address(refinancer), block.timestamp, calls)));

        assertEq(loan.paymentInterval(), 1_000_000);
        assertEq(loan.dateCalled(),      start + 1_200_000);
        assertEq(loan.dateImpaired(),    start + 1_200_000);
        assertEq(loan.datePaid(),        0);
        assertEq(loan.paymentDueDate(),  start + interval);
        assertEq(loan.principal(),       principal);

        (
            ,
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        ) = loan.paymentBreakdown(block.timestamp);

        uint256 totalPayment = interest_ + lateInterest_ + delegateServiceFee_ + platformServiceFee_;

        // Mint the borrower the partial payments
        asset.mint(borrower, totalPayment);

        // Mint the lender the principal increase
        asset.mint(address(lender), principalDiff);

        uint256 initialLenderBalance   = asset.balanceOf(address(lender));
        uint256 initialBorrowerBalance = asset.balanceOf(address(borrower));

        // Set up the mock lender to expect it's `claim` to be called with these specific values.
        lender.__expectCall();
        lender.claim(
            (int256(principalDiff) * -1),
            interest_ + lateInterest_,
            delegateServiceFee_ ,
            platformServiceFee_,
            uint40(block.timestamp + 1_000_000)
        );

        vm.prank(borrower);
        loan.acceptNewTerms(address(refinancer), block.timestamp, calls);

        uint256 finalLenderBalance   = asset.balanceOf(address(lender));
        uint256 finalBorrowerBalance = asset.balanceOf(address(borrower));

        assertEq(finalLenderBalance,   initialLenderBalance   - principalDiff + totalPayment);
        assertEq(finalBorrowerBalance, initialBorrowerBalance + principalDiff - totalPayment);

        assertEq(loan.paymentInterval(), 1_000_000);
        assertEq(loan.dateCalled(),      0);
        assertEq(loan.dateImpaired(),    0);
        assertEq(loan.datePaid(),        start + (interval / 2));
        assertEq(loan.paymentDueDate(),  start + (interval / 2) + interval);
        assertEq(loan.principal(),       principal + principalDiff);
    }

    function test_acceptNewTerms_principalDecrease() external {
        // Warp to exactly the payment due date
        vm.warp(start + (interval / 2));

        bytes[] memory calls = _encodeCall(abi.encodeWithSignature("decreasePrincipal(uint256)", principalDiff));

        loan.__setRefinanceCommitment(keccak256(abi.encode(address(refinancer), block.timestamp, calls)));

        assertEq(loan.paymentInterval(), 1_000_000);
        assertEq(loan.dateCalled(),      start + 1_200_000);
        assertEq(loan.dateImpaired(),    start + 1_200_000);
        assertEq(loan.datePaid(),        0);
        assertEq(loan.paymentDueDate(),  start + interval);
        assertEq(loan.principal(),       principal);

        (
            ,
            uint256 interest_,
            uint256 lateInterest_,
            uint256 delegateServiceFee_,
            uint256 platformServiceFee_
        ) = loan.paymentBreakdown(block.timestamp);

        uint256 totalPayment = interest_ + lateInterest_ + delegateServiceFee_ + platformServiceFee_;

        // Mint the borrower the partial payments
        asset.mint(borrower, totalPayment + principalDiff);

        uint256 initialLenderBalance   = asset.balanceOf(address(lender));
        uint256 initialBorrowerBalance = asset.balanceOf(address(borrower));

        // Set up the mock lender to expect it's `claim` to be called with these specific values.
        lender.__expectCall();
        lender.claim(
            int256(principalDiff),
            interest_ + lateInterest_,
            delegateServiceFee_,
            platformServiceFee_,
            uint40(block.timestamp + 1_000_000)
        );

        vm.prank(borrower);
        loan.acceptNewTerms(address(refinancer), block.timestamp, calls);

        uint256 finalLenderBalance   = asset.balanceOf(address(lender));
        uint256 finalBorrowerBalance = asset.balanceOf(address(borrower));

        assertEq(asset.balanceOf(address(loan)), 0);
        assertEq(finalLenderBalance,   initialLenderBalance   + principalDiff + totalPayment);
        assertEq(finalBorrowerBalance, initialBorrowerBalance - principalDiff - totalPayment);

        assertEq(loan.paymentInterval(), 1_000_000);
        assertEq(loan.dateCalled(),      0);
        assertEq(loan.dateImpaired(),    0);
        assertEq(loan.datePaid(),        start + (interval / 2));
        assertEq(loan.paymentDueDate(),  start + (interval / 2) + interval);
        assertEq(loan.principal(),       principal - principalDiff);
    }

    function _encodeCall(bytes memory call) internal pure returns (bytes[] memory calls) {
        calls = new bytes[](1);
        calls[0] = call;
    }

}
