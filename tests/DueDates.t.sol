// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { MockERC20 } from "../modules/erc20/contracts/test/mocks/MockERC20.sol";

import { MapleLoanHarness }   from "./utils/Harnesses.sol";
import { console2, TestBase } from "./utils/TestBase.sol";

contract DueDatesTests is TestBase {

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

    function test_dueDates_loanNotFunded() external {
        vm.expectRevert("ML:DD:INACTIVE");
        loan.__dueDates();
    }

    function test_dueDates_loanFunded() external {
        loan.__setDateFunded(start);

        ( uint256 callDueDate, uint256 impairedDueDate, uint256 normalDueDate ) = loan.__dueDates();

        assertEq(callDueDate,     0);
        assertEq(impairedDueDate, 0);
        assertEq(normalDueDate,   start + 30 days);

        assertEq(loan.paymentDueDate(), normalDueDate);
    }

    function test_dueDates_paymentMade() external {
        loan.__setDateFunded(start);
        loan.__setDatePaid(start + 15 days);

        ( uint256 callDueDate, uint256 impairedDueDate, uint256 normalDueDate ) = loan.__dueDates();

        assertEq(callDueDate,     0);
        assertEq(impairedDueDate, 0);
        assertEq(normalDueDate,   start + 15 days + 30 days);

        assertEq(loan.paymentDueDate(), normalDueDate);
    }

    function test_dueDates_loanCalled() external {
        loan.__setDateFunded(start);
        loan.__setDateCalled(start + 15 days);

        ( uint256 callDueDate, uint256 impairedDueDate, uint256 normalDueDate ) = loan.__dueDates();

        assertEq(callDueDate,     start + 15 days + 3 days);
        assertEq(impairedDueDate, 0);
        assertEq(normalDueDate,   start + 30 days);

        assertEq(loan.paymentDueDate(), callDueDate);
    }

    function test_dueDates_loanImpaired() external {
        loan.__setDateFunded(start);
        loan.__setDateImpaired(start + 15 days);

        ( uint256 callDueDate, uint256 impairedDueDate, uint256 normalDueDate ) = loan.__dueDates();

        assertEq(callDueDate,     0);
        assertEq(impairedDueDate, start + 15 days);
        assertEq(normalDueDate,   start + 30 days);

        assertEq(loan.paymentDueDate(), impairedDueDate);
    }

    function test_dueDates_loanImpairedAndCalled_impairEarliest() external {
        loan.__setDateFunded(start);
        loan.__setDateImpaired(start + 15 days);
        loan.__setDateCalled(start + 16 days);

        ( uint256 callDueDate, uint256 impairedDueDate, uint256 normalDueDate ) = loan.__dueDates();

        assertEq(callDueDate,     start + 16 days + 3 days);
        assertEq(impairedDueDate, start + 15 days);
        assertEq(normalDueDate,   start + 30 days);

        assertEq(loan.paymentDueDate(), impairedDueDate);
    }

    function test_dueDates_loanImpairedAndCalled_callEarliest() external {
        loan.__setDateFunded(start);
        loan.__setDateImpaired(start + 19 days);
        loan.__setDateCalled(start + 15 days);

        ( uint256 callDueDate, uint256 impairedDueDate, uint256 normalDueDate ) = loan.__dueDates();

        assertEq(callDueDate,     start + 15 days + 3 days);
        assertEq(impairedDueDate, start + 19 days);
        assertEq(normalDueDate,   start + 30 days);

        assertEq(loan.paymentDueDate(), callDueDate);
    }

    function test_dueDates_loanImpairedAndCalled_paymentEarliest() external {
        loan.__setDateFunded(start);
        loan.__setDateImpaired(start + 31 days);
        loan.__setDateCalled(start + 32 days);

        ( uint256 callDueDate, uint256 impairedDueDate, uint256 normalDueDate ) = loan.__dueDates();

        assertEq(callDueDate,     start + 32 days + 3 days);
        assertEq(impairedDueDate, start + 31 days);
        assertEq(normalDueDate,   start + 30 days);

        assertEq(loan.paymentDueDate(), normalDueDate);
    }

}
