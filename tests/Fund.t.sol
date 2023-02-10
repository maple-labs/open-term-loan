// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { MockERC20 } from "../modules/erc20/contracts/test/mocks/MockERC20.sol";

import { MapleLoanHarness } from "./utils/Harnesses.sol";
import { TestBase }         from "./utils/TestBase.sol";

contract FundTests is TestBase {

    address borrower;
    address lender;

    MapleLoanHarness loan;

    function setUp() public override {
        super.setUp();

        borrower = makeAddr("borrower");
        lender   = makeAddr("lender");

        asset = address(new MockERC20("Asset", "A", 6));
        loan  = MapleLoanHarness(createLoan({
            borrower:    borrower,
            lender:      lender,
            fundsAsset:  address(asset),
            principal:   100_000e6,
            termDetails: [uint32(5 days), uint32(5 days), uint32(30 days)],
            rates:       [uint256(0.1e6), uint256(0), uint256(0)]
        }));

        deal(asset, lender, 100_000e6);

        vm.prank(lender);
        MockERC20(asset).approve(address(loan), type(uint256).max);

        vm.warp(start);
    }

    function test_fund_notLender() external {
        vm.expectRevert("ML:F:NOT_LENDER");
        loan.fund();
    }

    function test_fund_loanActive() external {
        loan.__setDateFunded(start);

        vm.prank(lender);
        vm.expectRevert("ML:F:LOAN_ACTIVE");
        loan.fund();
    }

    function test_fund_insufficientBalanceBoundary() external {
        deal(asset, lender, 100_000e6 - 1);

        vm.prank(lender);
        vm.expectRevert("ML:F:TRANSFER_FROM_FAILED");
        loan.fund();

        deal(asset, lender, 100_000e6);

        vm.prank(lender);
        loan.fund();
    }

    function test_fund_insufficientApprovalBoundary() external {
        vm.prank(lender);
        MockERC20(asset).approve(address(loan), 100_000e6 - 1);

        vm.prank(lender);
        vm.expectRevert("ML:F:TRANSFER_FROM_FAILED");
        loan.fund();

        vm.prank(lender);
        MockERC20(asset).approve(address(loan), 100_000e6);

        vm.prank(lender);
        loan.fund();
    }

    function test_fund_success() external {
        deal(asset, lender, 150_000e6);

        assertEq(MockERC20(asset).balanceOf(borrower),      0);
        assertEq(MockERC20(asset).balanceOf(lender),        150_000e6);
        assertEq(MockERC20(asset).balanceOf(address(loan)), 0);

        assertEq(loan.dateFunded(), 0);

        vm.prank(lender);
        MockERC20(asset).approve(address(loan), type(uint256).max);

        vm.prank(lender);
        ( uint256 fundsLent_, uint40 paymentDueDate_ ) = loan.fund();

        assertEq(fundsLent_,      100_000e6);
        assertEq(paymentDueDate_, start + 30 days);

        assertEq(MockERC20(asset).balanceOf(borrower),      100_000e6);
        assertEq(MockERC20(asset).balanceOf(lender),        50_000e6);
        assertEq(MockERC20(asset).balanceOf(address(loan)), 0);

        assertEq(loan.dateFunded(), start);
    }

}
