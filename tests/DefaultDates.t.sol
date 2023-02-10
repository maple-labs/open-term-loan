// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { MapleLoanHarness }   from "./utils/Harnesses.sol";
import { console2, TestBase } from "./utils/TestBase.sol";

contract DefaultDatesTests is TestBase {

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

        assertEq(loan.dateFunded(),   0);
        assertEq(loan.dateCalled(),   0);
        assertEq(loan.dateImpaired(), 0);
        assertEq(loan.datePaid(),     0);

        // Fund loan by setting funding date
        loan.__setDateFunded(start);

        assertEq(loan.dateFunded(), start);

        ( uint256 callDefaultDate, uint256 impairedDefaultDate, uint256 normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     0);
        assertEq(impairedDefaultDate, 0);
        assertEq(normalDefaultDate,   start + 30 days + 5 days);

        assertEq(loan.defaultDate(), start + 30 days + 5 days);
        assertEq(loan.defaultDate(), normalDefaultDate);
    }

    // NOTE: The default date should be the smallest timestamp between call, impairment and paymentDueDate including notice/grace periods.

    function test_defaultDates_loanNotFunded() external {
        // Mock loan not being funded
        loan.__setDateFunded(0);

        vm.expectRevert("ML:DD:INACTIVE");
        loan.__defaultDates();
    }

    function test_defaultDates_loanFundedNoPayments_impair() external {
        // Impair loan by setting dateImpaired
        loan.__setDateImpaired(start + 15 days);

        assertEq(loan.dateImpaired(), start + 15 days);

        ( uint256 callDefaultDate, uint256 impairedDefaultDate, uint256 normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     0);
        assertEq(impairedDefaultDate, start + 15 days + 5 days);
        assertEq(normalDefaultDate,   start + 30 days + 5 days);

        // The default date should be the dateImpaired + gracePeriod
        assertEq(loan.defaultDate(), start + 15 days + 5 days);
        assertEq(loan.defaultDate(), impairedDefaultDate);
    }

    function test_defaultDates_loanFundedNoPayments_call() external {
        // Call loan by setting dateCalled
        loan.__setDateCalled(start + 15 days);

        assertEq(loan.dateCalled(), start + 15 days);

        ( uint256 callDefaultDate, uint256 impairedDefaultDate, uint256 normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     start + 15 days + 3 days);
        assertEq(impairedDefaultDate, 0);
        assertEq(normalDefaultDate,   start + 30 days + 5 days);

        // The default date should be the dateCalled + noticePeriod
        assertEq(loan.defaultDate(), start + 15 days + 3 days);
        assertEq(loan.defaultDate(), callDefaultDate);
    }

    // TODO: Consider Fuzz test for this scenario
    function test_defaultDates_loanFundedNoPayments_impairThenCall() external {
        // Impair loan by setting dateImpaired
        loan.__setDateImpaired(start + 15 days);

        assertEq(loan.dateImpaired(), start + 15 days);

        ( uint256 callDefaultDate, uint256 impairedDefaultDate, uint256 normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     0);
        assertEq(impairedDefaultDate, start + 15 days + 5 days);
        assertEq(normalDefaultDate,   start + 30 days + 5 days);

        assertEq(loan.defaultDate(), start + 15 days + 5 days);
        assertEq(loan.defaultDate(), impairedDefaultDate);

        // Call loan by setting dateCalled
        loan.__setDateCalled(start + 16 days);

        assertEq(loan.dateCalled(), start + 16 days);

        ( callDefaultDate, impairedDefaultDate, normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     start + 16 days + 3 days);
        assertEq(impairedDefaultDate, start + 15 days + 5 days);
        assertEq(normalDefaultDate,   start + 30 days + 5 days);

        // The default date should be the dateCalled + noticePeriod as its smaller than the dateImpaired + gracePeriod
        assertEq(loan.defaultDate(), start + 16 days + 3 days);
        assertEq(loan.defaultDate(), callDefaultDate);
    }

    function test_defaultDates_loanFundedNoPayments_callThenImpair() external {
        // Call loan by setting dateCalled
        loan.__setDateCalled(start + 15 days);

        assertEq(loan.dateCalled(), start + 15 days);

        ( uint256 callDefaultDate, uint256 impairedDefaultDate, uint256 normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     start + 15 days + 3 days);
        assertEq(impairedDefaultDate, 0);
        assertEq(normalDefaultDate,   start + 30 days + 5 days);

        assertEq(loan.defaultDate(), start + 15 days + 3 days);
        assertEq(loan.defaultDate(), callDefaultDate);

        // Impair loan by setting dateImpaired
        loan.__setDateImpaired(start + 16 days);

        assertEq(loan.dateImpaired(), start + 16 days);

        ( callDefaultDate, impairedDefaultDate, normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     start + 15 days + 3 days);
        assertEq(impairedDefaultDate, start + 16 days + 5 days);
        assertEq(normalDefaultDate,   start + 30 days + 5 days);

        // The default date should be the dateCalled + noticePeriod as its smaller than the dateImpaired + gracePeriod
        assertEq(loan.defaultDate(), start + 15 days + 3 days);
        assertEq(loan.defaultDate(), callDefaultDate);
    }

    function test_defaultDates_firstPaymentMade() external {
        // First payment made by setting datePaid
        loan.__setDatePaid(start + 15 days);

        assertEq(loan.datePaid(),       start + 15 days);
        assertEq(loan.paymentDueDate(), start + 15 days + 30 days);

        ( uint256 callDefaultDate, uint256 impairedDefaultDate, uint256 normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     0);
        assertEq(impairedDefaultDate, 0);
        assertEq(normalDefaultDate,   start + 45 days + 5 days);

        // The default date should be the paymentDueDate + gracePeriod
        assertEq(loan.defaultDate(), start + 45 days + 5 days);
        assertEq(loan.defaultDate(), normalDefaultDate);
    }

    function test_defaultDates_firstPaymentMade_impair() external {
        // First payment made by setting datePaid
        loan.__setDatePaid(start + 15 days);

        assertEq(loan.datePaid(),       start + 15 days);
        assertEq(loan.paymentDueDate(), start + 15 days + 30 days);

        ( uint256 callDefaultDate, uint256 impairedDefaultDate, uint256 normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     0);
        assertEq(impairedDefaultDate, 0);
        assertEq(normalDefaultDate,   start + 45 days + 5 days);

        assertEq(loan.defaultDate(), start + 45 days + 5 days);
        assertEq(loan.defaultDate(), normalDefaultDate);

        // Impair loan by setting dateImpaired
        loan.__setDateImpaired(start + 16 days);

        assertEq(loan.dateImpaired(), start + 16 days);

        ( callDefaultDate, impairedDefaultDate, normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     0);
        assertEq(impairedDefaultDate, start + 16 days + 5 days);
        assertEq(normalDefaultDate,   start + 45 days + 5 days);

        // The default date should be the dateImpaired + gracePeriod
        assertEq(loan.defaultDate(), start + 16 days + 5 days);
        assertEq(loan.defaultDate(), impairedDefaultDate);
    }

    function test_defaultDates_firstPaymentMade_call() external {
        // First payment made by setting datePaid
        loan.__setDatePaid(start + 15 days);

        assertEq(loan.datePaid(),       start + 15 days);
        assertEq(loan.paymentDueDate(), start + 15 days + 30 days);

        ( uint256 callDefaultDate, uint256 impairedDefaultDate, uint256 normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     0);
        assertEq(impairedDefaultDate, 0);
        assertEq(normalDefaultDate,   start + 45 days + 5 days);

        assertEq(loan.defaultDate(), start + 45 days + 5 days);
        assertEq(loan.defaultDate(), normalDefaultDate);

        // Call loan by setting dateCalled
        loan.__setDateCalled(start + 16 days);

        assertEq(loan.dateCalled(), start + 16 days);

        ( callDefaultDate, impairedDefaultDate, normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     start + 16 days + 3 days);
        assertEq(impairedDefaultDate, 0);
        assertEq(normalDefaultDate,   start + 45 days + 5 days);

        // The default date should be the dateCalled + noticePeriod
        assertEq(loan.defaultDate(), start + 16 days + 3 days);
        assertEq(loan.defaultDate(), callDefaultDate);
    }

    function test_defaultDates_firstPaymentMade_impairThenCall() external {
        // First payment made by setting datePaid
        loan.__setDatePaid(start + 15 days);

        assertEq(loan.datePaid(),       start + 15 days);
        assertEq(loan.paymentDueDate(), start + 15 days + 30 days);

        ( uint256 callDefaultDate, uint256 impairedDefaultDate, uint256 normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     0);
        assertEq(impairedDefaultDate, 0);
        assertEq(normalDefaultDate,   start + 45 days + 5 days);

        assertEq(loan.defaultDate(), start + 45 days + 5 days);
        assertEq(loan.defaultDate(), normalDefaultDate);

        // Impair loan by setting dateImpaired
        loan.__setDateImpaired(start + 16 days);

        assertEq(loan.dateImpaired(), start + 16 days);

        ( callDefaultDate, impairedDefaultDate, normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     0);
        assertEq(impairedDefaultDate, start + 16 days + 5 days);
        assertEq(normalDefaultDate,   start + 45 days + 5 days);

        assertEq(loan.defaultDate(), start + 16 days + 5 days);
        assertEq(loan.defaultDate(), impairedDefaultDate);

        // Call loan by setting dateCalled
        loan.__setDateCalled(start + 17 days);

        assertEq(loan.dateCalled(), start + 17 days);

        ( callDefaultDate, impairedDefaultDate, normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     start + 17 days + 3 days);
        assertEq(impairedDefaultDate, start + 16 days + 5 days);
        assertEq(normalDefaultDate,   start + 45 days + 5 days);

        // The default date should be the dateCalled + noticePeriod
        assertEq(loan.defaultDate(), start + 17 days + 3 days);
        assertEq(loan.defaultDate(), callDefaultDate);
    }

    function test_defaultDates_firstPaymentMade_callThenImpair() external {
        // First payment made by setting datePaid
        loan.__setDatePaid(start + 15 days);

        assertEq(loan.datePaid(),       start + 15 days);
        assertEq(loan.paymentDueDate(), start + 15 days + 30 days);

        ( uint256 callDefaultDate, uint256 impairedDefaultDate, uint256 normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     0);
        assertEq(impairedDefaultDate, 0);
        assertEq(normalDefaultDate,   start + 45 days + 5 days);

        assertEq(loan.defaultDate(), start + 45 days + 5 days);
        assertEq(loan.defaultDate(), normalDefaultDate);

        // Call loan by setting dateCalled
        loan.__setDateCalled(start + 16 days);

        assertEq(loan.dateCalled(), start + 16 days);

        ( callDefaultDate, impairedDefaultDate, normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     start + 16 days + 3 days);
        assertEq(impairedDefaultDate, 0);
        assertEq(normalDefaultDate,   start + 45 days + 5 days);

        assertEq(loan.defaultDate(), start + 16 days + 3 days);
        assertEq(loan.defaultDate(), callDefaultDate);

        // Impair loan by setting dateImpaired
        loan.__setDateImpaired(start + 17 days);

        assertEq(loan.dateImpaired(), start + 17 days);

        ( callDefaultDate, impairedDefaultDate, normalDefaultDate ) = loan.__defaultDates();

        assertEq(callDefaultDate,     start + 16 days + 3 days);
        assertEq(impairedDefaultDate, start + 17 days + 5 days);
        assertEq(normalDefaultDate,   start + 45 days + 5 days);

        // The default date should be the dateCalled + noticePeriod
        assertEq(loan.defaultDate(), start + 16 days + 3 days);
        assertEq(loan.defaultDate(), callDefaultDate);
    }

}
