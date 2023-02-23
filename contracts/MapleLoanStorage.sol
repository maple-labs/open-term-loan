// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleLoanStorage } from "./interfaces/IMapleLoanStorage.sol";

/// @title MapleLoanStorage defines the storage layout of MapleLoan.
abstract contract MapleLoanStorage is IMapleLoanStorage {

    // TODO: Confirm uint32s and uint40s.
    // TODO: Rename `lateInterestPremium` to `lateInterestPremiumRate`?

    address public override fundsAsset;       // The address of the asset used as funds.
    address public override borrower;         // The address of the borrower.
    address public override lender;           // The address of the lender.
    address public override pendingBorrower;  // The address of the pendingBorrower, the only address that can accept the borrower role.
    address public override pendingLender;    // The address of the pendingLender, the only address that can accept the lender role.

    uint32 public override gracePeriod;      // The number of seconds a payment can be late.
    uint32 public override noticePeriod;     // The number of seconds after a loan is called after which the borrower can be considered in default.
    uint32 public override paymentInterval;  // The number of seconds between payments.

    uint40 public override dateCalled;
    uint40 public override dateFunded;
    uint40 public override dateImpaired;
    uint40 public override datePaid;

    uint256 public override calledPrincipal;  // The amount of principal yet to be returned to satisfy the loan call.
    uint256 public override principal;        // The amount of principal yet to be paid down.

    uint64 public override delegateServiceFeeRate;  // The annualized delegate service fee rate.
    uint64 public override interestRate;            // The annualized interest rate of the loan.
    uint64 public override lateFeeRate;             // The fee rate for late payments.
    uint64 public override lateInterestPremium;     // The amount to increase the interest rate by for late payments.
    uint64 public override platformServiceFeeRate;  // The annualized platform service fee rate.

}
