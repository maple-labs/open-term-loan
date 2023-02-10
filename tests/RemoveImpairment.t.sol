// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { MockERC20 } from "../modules/erc20/contracts/test/mocks/MockERC20.sol";

import { MapleLoanHarness }   from "./utils/Harnesses.sol";
import { console2, TestBase } from "./utils/TestBase.sol";

contract RemoveImpairmentTests is TestBase {

    address borrower;
    address lender;

    MapleLoanHarness loan;

    function setUp() public override {
        super.setUp();

        borrower = makeAddr("borrower");
        lender   = makeAddr("lender");

        loan = MapleLoanHarness(createLoan({
            borrower:    borrower,
            lender:      lender,
            fundsAsset:  asset,
            principal:   100_000e6,
            termDetails: [uint32(5 days), uint32(3 days), uint32(30 days)],
            rates:       [uint256(0.1e6), uint256(0), uint256(0)]
        }));
    }

    function test_removeImpairment_notLender() external {
        vm.expectRevert("ML:RI:NOT_LENDER");
        loan.removeImpairment();
    }

    function test_removeImpairment_notImpaired() external {
        // Set the date to mock the loan being funded.
        loan.__setDateFunded(start);

        vm.expectRevert("ML:RI:NOT_IMPAIRED");
        vm.prank(lender);
        loan.removeImpairment();
    }

    function test_removeImpairment() external {
        // Set the date to mock the loan being funded.
        loan.__setDateFunded(start);
        loan.__setDateImpaired(start + 10 days);

        assertEq(loan.dateImpaired(),   start + 10 days);
        assertEq(loan.defaultDate(),    start + 10 days + 5 days);
        assertEq(loan.paymentDueDate(), start + 10 days);

        vm.warp(start + 12 days);
        vm.prank(lender);
        ( uint256 paymentDueDate, uint256 defaultDate ) = loan.removeImpairment();

        assertEq(loan.dateImpaired(),   0);
        assertEq(loan.defaultDate(),    start + 30 days + 5 days);  // Goes back to original default date
        assertEq(defaultDate,           start + 30 days + 5 days);
        assertEq(loan.paymentDueDate(), start + 30 days);           // Goes back to original payment due date
        assertEq(paymentDueDate,        start + 30 days);
    }

}
