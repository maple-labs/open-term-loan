// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { TestBase } from "./utils/TestBase.sol";

import { MapleLoanHarness } from "./utils/Harnesses.sol";

contract PaymentBreakdownTests is TestBase {

    address borrower;
    address lender;

    MapleLoanHarness loan;

    function setUp() public override {
        super.setUp();
    }

    // Full year payment interval at 10%
    function test_paymentBreakdown_fixture1() public {
        loan = _createFixture({
            principal:       1_000_000e6,
            paymentInterval: 365 days,
            paymentDate:     365 days,
            rates:           [uint256(0.10e18), uint256(0), uint256(0)]  // Interest rate, late fee rate, late interest premium
        });

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        assertEq(interest,     100_000e6);
        assertEq(lateInterest, 0);
    }

    // 30 day payment interval
    function test_paymentBreakdown_fixture2() public {
        loan = _createFixture({
            principal:       1_000_000e6,
            paymentInterval: 30 days,
            paymentDate:     30 days,
            rates:           [uint256(0.10e18), uint256(0), uint256(0)]
        });

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        assertEq(interest,     8_219.178082e6);
        assertEq(lateInterest, 0);
    }

    // Full year at 10% interest, 0.1 years early at 10% interest (full year for easy validation)
    function test_paymentBreakdown_fixture3() public {
        loan = _createFixture({
            principal:       1_000_000e6,
            paymentInterval: 365 days,
            paymentDate:     365 days - (365 days / 10),
            rates:           [uint256(0.10e18), uint256(0), uint256(0.05e18)]
        });

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        assertEq(interest,     90_000e6);  // 1 year at 10% interest
        assertEq(lateInterest, 0);
    }

    // Full year at 10% interest, 0.1 years late at (10% + 5%) interest (full year for easy validation)
    function test_paymentBreakdown_fixture4() public {
        loan = _createFixture({
            principal:       1_000_000e6,
            paymentInterval: 365 days,
            paymentDate:     365 days + (365 days / 10),
            rates:           [uint256(0.10e18), uint256(0), uint256(0.05e18)]
        });

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        assertEq(interest,     100_000e6);  // 1 year at 10% interest
        assertEq(lateInterest, 15_000e6);   // 0.1 years at (10% + 5%) interest (15_000e6)
    }

    // Half year at 10% interest, 0.1 years late at 10% interest + 0.9% flat fee on principal
    function test_paymentBreakdown_fixture5() public {
        uint256 halfYear = 365 days / 2;

        loan = _createFixture({
            principal:       1_000_000e6,
            paymentInterval: halfYear,
            paymentDate:     halfYear + (365 days / 10),
            rates:           [uint256(0.10e18), uint256(0.009e18), uint256(0)]
        });

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        assertEq(interest,     50_000e6);  // 0.5 years at 10% interest
        assertEq(lateInterest, 19_000e6);  // 0.1 years at 10% interest (10_000e6) + 0.9% of flat fee (9_000e6)
    }

    // Half year at 10% interest, 0.1 years late at (10% + 5%) interest + 0.9% flat fee on principal
    function test_paymentBreakdown_fixture6() public {
        uint256 halfYear = 365 days / 2;

        loan = _createFixture({
            principal:       1_000_000e6,
            paymentInterval: halfYear,
            paymentDate:     halfYear + (365 days / 10), // 10% of a year late
            rates:           [uint256(0.10e18), uint256(0.02e18), uint256(0.05e18)]
        });

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        assertEq(interest,     50_000e6);  // 0.5 years at 10% interest
        assertEq(lateInterest, 35_000e6);  // 0.1 years at (10% + 5%) interest (15_000e6) + 2% of flat fee (20_000e6)
    }

}
