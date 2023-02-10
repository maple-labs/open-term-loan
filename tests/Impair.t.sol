// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { MockERC20 } from "../modules/erc20/contracts/test/mocks/MockERC20.sol";

import { MapleLoanHarness }   from "./utils/Harnesses.sol";
import { console2, TestBase } from "./utils/TestBase.sol";

contract ImpairTests is TestBase {

    address borrower;
    address lender;

    MapleLoanHarness loan;

    function setUp() public override {
        super.setUp();

        borrower = makeAddr("borrower");
        lender   = makeAddr("lender");

        // TODO: Investigate adding this to TestBase, adding constants everywhere.
        loan = MapleLoanHarness(createLoan({
            borrower:    borrower,
            lender:      lender,
            fundsAsset:  asset,
            principal:   100_000e6,
            termDetails: [uint32(5 days), uint32(3 days), uint32(30 days)],
            rates:       [uint256(0.1e6), uint256(0), uint256(0)]
        }));
    }

    function test_impair_notLender() external {
        vm.expectRevert("ML:I:NOT_LENDER");
        loan.impair();
    }

    function test_impair_loanNotFunded() external {
        vm.expectRevert("ML:I:LOAN_INACTIVE");
        vm.prank(lender);
        loan.impair();
    }

    function test_impair_loanAlreadyImpaired() external {
        loan.__setDateFunded(start);

        vm.prank(lender);
        loan.impair();

        vm.expectRevert("ML:I:ALREADY_IMPAIRED");
        vm.prank(lender);
        loan.impair();
    }

    function test_impair() external {
        // Set the date to mock the loan being funded.
        loan.__setDateFunded(start);

        assertEq(loan.defaultDate(),    start + 30 days + 5 days);
        assertEq(loan.paymentDueDate(), start + 30 days);

        vm.warp(start + 10 days);

        vm.prank(lender);
        ( uint256 paymentDueDate, uint256 defaultDate ) = loan.impair();

        assertEq(loan.dateImpaired(),   start + 10 days);
        assertEq(loan.defaultDate(),    start + 10 days + 5 days);
        assertEq(defaultDate,           start + 10 days + 5 days);
        assertEq(loan.paymentDueDate(), start + 10 days);
        assertEq(paymentDueDate,        start + 10 days);
    }

}
