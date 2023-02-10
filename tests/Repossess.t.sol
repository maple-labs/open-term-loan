// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { MockERC20 } from "../modules/erc20/contracts/test/mocks/MockERC20.sol";

import { MapleLoanHarness }   from "./utils/Harnesses.sol";
import { MockRevertingERC20 } from "./utils/Mocks.sol";
import { TestBase }           from "./utils/TestBase.sol";

contract RepossessTests is TestBase {

    address borrower;
    address lender;

    MapleLoanHarness loan;

    uint256 constant gracePeriod          = 5 days;
    uint256 constant interestRate         = 0.1e6;
    uint256 constant lateFeeRate          = 0;
    uint256 constant laterInterestPremium = 0;
    uint256 constant noticePeriod         = 3 days;
    uint256 constant paymentInterval      = 30 days;
    uint256 constant principal            = 100_000e6;

    function setUp() public override {
        super.setUp();

        borrower = makeAddr("borrower");
        lender   = makeAddr("lender");

        loan = MapleLoanHarness(createLoan({
            borrower:    borrower,
            lender:      lender,
            fundsAsset:  asset,
            principal:   100_000e6,
            termDetails: [uint32(gracePeriod), uint32(noticePeriod), uint32(paymentInterval)],
            rates:       [uint256(0.1e6), uint256(0), uint256(0)]
        }));

        loan.__setDateFunded(start);

        assertEq(MockERC20(asset).balanceOf(borrower),      0);
        assertEq(MockERC20(asset).balanceOf(lender),        0);
        assertEq(MockERC20(asset).balanceOf(address(loan)), 0);

        assertEq(loan.gracePeriod(),         gracePeriod);
        assertEq(loan.noticePeriod(),        noticePeriod);
        assertEq(loan.paymentInterval(),     paymentInterval);
        assertEq(loan.dateCalled(),          0);
        assertEq(loan.datePaid(),            0);
        assertEq(loan.dateFunded(),          start);
        assertEq(loan.dateImpaired(),        0);
        assertEq(loan.calledPrincipal(),     0);
        assertEq(loan.principal(),           principal);
        assertEq(loan.interestRate(),        interestRate);
        assertEq(loan.lateFeeRate(),         0);
        assertEq(loan.lateInterestPremium(), 0);
        assertEq(loan.borrower(),            borrower);
        assertEq(loan.fundsAsset(),          asset);
        assertEq(loan.lender(),              lender);
        assertEq(loan.pendingBorrower(),     address(0));
        assertEq(loan.pendingLender(),       address(0));
    }

    function test_repossess_notLender() external {
        vm.expectRevert("ML:R:NOT_LENDER");
        loan.repossess(lender);
    }

    function test_repossess_defaultDateBoundary() external {
        // Warp to when the loan is first in default.
        vm.warp(start + paymentInterval + gracePeriod);

        vm.prank(lender);
        vm.expectRevert("ML:R:NOT_IN_DEFAULT");
        loan.repossess(lender);

        vm.warp(start + paymentInterval + gracePeriod + 1 seconds);

        vm.prank(lender);
        loan.repossess(lender);
    }

    function test_repossess_transferFail() external {
        asset = address(new MockRevertingERC20("Asset", "A", 6));

        loan.__setFundsAsset(asset);

        deal(asset, address(loan), 1);

        vm.prank(lender);
        vm.expectRevert("ML:R:TRANSFER_FAILED");
        loan.repossess(lender);

        asset = address(new MockERC20("Asset", "A", 6));

        loan.__setFundsAsset(asset);

        deal(asset, address(loan), 1);

        vm.prank(lender);
        loan.repossess(lender);
    }

    function test_repossess_noFunds() external {
        vm.prank(lender);
        loan.repossess(lender);

        assertEq(MockERC20(asset).balanceOf(borrower),      0);
        assertEq(MockERC20(asset).balanceOf(lender),        0);
        assertEq(MockERC20(asset).balanceOf(address(loan)), 0);

        assertEq(loan.gracePeriod(),         0);
        assertEq(loan.noticePeriod(),        0);
        assertEq(loan.paymentInterval(),     0);
        assertEq(loan.dateCalled(),          0);
        assertEq(loan.datePaid(),            0);
        assertEq(loan.dateFunded(),          0);
        assertEq(loan.dateImpaired(),        0);
        assertEq(loan.calledPrincipal(),     0);
        assertEq(loan.principal(),           0);
        assertEq(loan.interestRate(),        0);
        assertEq(loan.lateFeeRate(),         0);
        assertEq(loan.lateInterestPremium(), 0);
        assertEq(loan.borrower(),            borrower);
        assertEq(loan.fundsAsset(),          asset);
        assertEq(loan.lender(),              lender);
    }

    function test_repossess_availableFunds() external {
        deal(asset, address(loan), 10_000e6);

        assertEq(MockERC20(asset).balanceOf(borrower),      0);
        assertEq(MockERC20(asset).balanceOf(lender),        0);
        assertEq(MockERC20(asset).balanceOf(address(loan)), 10_000e6);

        vm.prank(lender);
        loan.repossess(lender);

        assertEq(MockERC20(asset).balanceOf(borrower),      0);
        assertEq(MockERC20(asset).balanceOf(lender),        10_000e6);
        assertEq(MockERC20(asset).balanceOf(address(loan)), 0);

        assertEq(loan.gracePeriod(),         0);
        assertEq(loan.noticePeriod(),        0);
        assertEq(loan.paymentInterval(),     0);
        assertEq(loan.dateCalled(),          0);
        assertEq(loan.datePaid(),            0);
        assertEq(loan.dateFunded(),          0);
        assertEq(loan.dateImpaired(),        0);
        assertEq(loan.calledPrincipal(),     0);
        assertEq(loan.principal(),           0);
        assertEq(loan.interestRate(),        0);
        assertEq(loan.lateFeeRate(),         0);
        assertEq(loan.lateInterestPremium(), 0);
        assertEq(loan.borrower(),            borrower);
        assertEq(loan.fundsAsset(),          asset);
        assertEq(loan.lender(),              lender);
    }

}
