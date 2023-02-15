// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { MapleLoanHarness } from "./utils/Harnesses.sol";
import { Utils }            from "./utils/Utils.sol";

contract PaymentBreakdownTests is Test, Utils {

    uint256 constant HUNDRED_PERCENT = 1e18;

    MapleLoanHarness loan = new MapleLoanHarness();

    function testFuzz_paymentBreakdown(
        uint256 paymentInterval,
        uint256 dateFunded,
        uint256 principal,
        uint256 interestRate,
        uint256 lateFeeRate,
        uint256 lateInterestPremium
    ) external {
        paymentInterval     = bound(paymentInterval,       1 days,                     365 days);
        dateFunded          = bound(dateFunded,            block.timestamp - 365 days, block.timestamp);
        principal           = bound(principal,             1e6,                        1e30);
        interestRate        = bound(interestRate,          0,                          1.00e18);
        lateFeeRate         = bound(lateFeeRate,           0,                          0.10e18);
        lateInterestPremium = bound(lateInterestPremium,   0,                          0.50e18);

        loan.__setDateFunded(dateFunded);
        loan.__setLateFeeRate(lateFeeRate);
        loan.__setLateInterestPremium(lateInterestPremium);
        loan.__setPaymentInterval(paymentInterval);
        loan.__setPrincipal(principal);
        loan.__setInterestRate(interestRate);

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        uint256 paymentDueDate = dateFunded + paymentInterval;

        // If late, `currentTime` is the `paymentInterval` and `lateTime` is time passed now, else  `currentTime` is time since funding.
        ( uint256 currentTime, uint256 lateTime ) =
            block.timestamp > paymentDueDate
                ? ( paymentInterval,              block.timestamp - paymentDueDate )
                : ( block.timestamp - dateFunded, 0                                );

        uint256 expectedInterest     = (principal * interestRate * currentTime) / (365 days * HUNDRED_PERCENT);
        uint256 expectedLateInterest = lateTime != 0
            ?
                (
                    ((principal * (interestRate + lateInterestPremium) * lateTime) / 365 days) + (principal * lateFeeRate)
                ) / HUNDRED_PERCENT
            : 0;

        assertEq(interest, expectedInterest);

        // Off-by-one due to reworked formula above. Better this than to use the exact same formula, which defeats the test's purpose.
        assertApproxEqAbs(lateInterest, expectedLateInterest, 1);
    }

    // Full year payment interval at 10%
    function test_paymentBreakdown_fixture1() external {
        uint256 paymentInterval = 365 days;
        uint256 dateFunded      = block.timestamp - paymentInterval;
        uint256 principal       = 1_000_000e6;
        uint256 interestRate    = 0.10e18;

        loan.__setDateFunded(dateFunded);
        loan.__setPaymentInterval(paymentInterval);
        loan.__setPrincipal(principal);
        loan.__setInterestRate(interestRate);

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        assertEq(interest,     100_000e6);
        assertEq(lateInterest, 0);
    }

    // 30 day payment interval at 10%
    function test_paymentBreakdown_fixture2() external {
        uint256 paymentInterval = 30 days;
        uint256 dateFunded      = block.timestamp - paymentInterval;
        uint256 principal       = 1_000_000e6;
        uint256 interestRate    = 0.10e18;

        loan.__setDateFunded(dateFunded);
        loan.__setPaymentInterval(paymentInterval);
        loan.__setPrincipal(principal);
        loan.__setInterestRate(interestRate);

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        assertEq(interest,     8_219.178082e6);
        assertEq(lateInterest, 0);
    }

    // Full year at 10% interest, 0.1 years early at 10% interest (full year for easy validation)
    function test_paymentBreakdown_fixture3() external {
        uint256 paymentInterval = 365 days;
        uint256 dateFunded      = block.timestamp - 365 days + (365 days / 10);
        uint256 principal       = 1_000_000e6;
        uint256 interestRate    = 0.10e18;

        loan.__setDateFunded(dateFunded);
        loan.__setPaymentInterval(paymentInterval);
        loan.__setPrincipal(principal);
        loan.__setInterestRate(interestRate);

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        assertEq(interest,     90_000e6);
        assertEq(lateInterest, 0);
    }

    // Full year at 10% interest, 0.1 years late at (10% + 5%) interest (full year for easy validation)
    function test_paymentBreakdown_fixture4() external {
        uint256 paymentInterval     = 365 days;
        uint256 dateFunded          = block.timestamp - 365 days - (365 days / 10);
        uint256 principal           = 1_000_000e6;
        uint256 interestRate        = 0.10e18;
        uint256 lateInterestPremium = 0.05e18;

        loan.__setDateFunded(dateFunded);
        loan.__setLateInterestPremium(lateInterestPremium);
        loan.__setPaymentInterval(paymentInterval);
        loan.__setPrincipal(principal);
        loan.__setInterestRate(interestRate);

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        assertEq(interest,     100_000e6);  // 1 year at 10% interest
        assertEq(lateInterest, 15_000e6);   // 0.1 years at (10% + 5%) interest (15_000e6)
    }

    // Half year at 10% interest, 0.1 years late at 10% interest + 0.9% flat fee on principal
    function test_paymentBreakdown_fixture5() external {
        uint256 paymentInterval = 365 days / 2;
        uint256 dateFunded      = block.timestamp - (365 days / 2) - (365 days / 10);
        uint256 principal       = 1_000_000e6;
        uint256 interestRate    = 0.10e18;
        uint256 lateFeeRate     = 0.009e18;

        loan.__setDateFunded(dateFunded);
        loan.__setLateFeeRate(lateFeeRate);
        loan.__setPaymentInterval(paymentInterval);
        loan.__setPrincipal(principal);
        loan.__setInterestRate(interestRate);

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        assertEq(interest,     50_000e6);  // 0.5 years at 10% interest
        assertEq(lateInterest, 19_000e6);  // 0.1 years at 10% interest (10_000e6) + 0.9% of flat fee (9_000e6)
    }

    // Half year at 10% interest, 0.1 years late at (10% + 5%) interest + 0.9% flat fee on principal
    function test_paymentBreakdown_fixture6() external {
        uint256 paymentInterval     = 365 days / 2;
        uint256 dateFunded          = block.timestamp - (365 days / 2) - (365 days / 10);
        uint256 principal           = 1_000_000e6;
        uint256 interestRate        = 0.10e18;
        uint256 lateFeeRate         = 0.009e18;
        uint256 lateInterestPremium = 0.05e18;

        loan.__setDateFunded(dateFunded);
        loan.__setLateFeeRate(lateFeeRate);
        loan.__setLateInterestPremium(lateInterestPremium);
        loan.__setPaymentInterval(paymentInterval);
        loan.__setPrincipal(principal);
        loan.__setInterestRate(interestRate);

        ( uint256 interest, uint256 lateInterest ) = loan.paymentBreakdown();

        assertEq(interest,     50_000e6);  // 0.5 years at 10% interest
        assertEq(lateInterest, 24_000e6);  // 0.1 years at (10% + 5%) interest (15_000e6) + 0.9% of flat fee (9_000e6)
    }

}
