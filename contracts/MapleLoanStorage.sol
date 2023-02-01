// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleLoanStorage } from "./interfaces/IMapleLoanStorage.sol";

/// @title MapleLoanStorage defines the storage layout of MapleLoan.
abstract contract MapleLoanStorage is IMapleLoanStorage {

    // TODO: Reorder variables and potentially pack slots.
    // TODO: Confirm uint32s and uint40s.

    // --- SLOT 0 --- //

    address public override fundsAsset;  // The address of the asset used as funds.

    uint32 public override gracePeriod;      // The number of seconds a payment can be late.
    uint32 public override noticePeriod;     // The number of seconds after a loan is called after which the borrower can be considered in default.
    uint32 public override paymentInterval;  // The number of seconds between payments.

    // --- SLOT 1 --- //

    address public override borrower;  // The address of the borrower.

    uint40 public override nextPaymentDueDate;          // The timestamp of due date of next payment.
    uint40 public override originalNextPaymentDueDate;  // The previous timestamp of due date of next payment. Used as a cache to allow reversion of loan impairment.

    uint16 private __unused;

    // --- SLOTS 2 - 8 --- //

    address public override lender;  // The address of the lender.
    address public override pendingBorrower;  // The address of the pendingBorrower, the only address that can accept the borrower role.
    address public override pendingLender;    // The address of the pendingLender, the only address that can accept the lender role.

    uint256 public override calledPrincipal;  // The amount of principal yet to be returned to satisfy the loan call.
    uint256 public override principal;        // The amount of principal yet to be paid down.

    // Rates
    uint256 public override interestRate;         // The annualized interest rate of the loan.
    uint256 public override lateFeeRate;          // The fee rate for late payments.
    uint256 public override lateInterestPremium;  // The amount to increase the interest rate by for late payments.

}
