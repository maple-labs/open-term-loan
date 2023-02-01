// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

/// @title MapleLoanStorage define the storage slots for MapleLoan, which is intended to be proxied.
interface IMapleLoanStorage {

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev The borrower of the loan, responsible for repayments.
     */
    function borrower() external view returns (address borrower_);

    /**
     *  @dev The amount of principal yet to be returned to satisfy the loan call.
     */
    function calledPrincipal() external view returns (uint256 calledPrincipal_);

    /**
     *  @dev The fundsAsset deposited by the lender to fund the loan.
     */
    function fundsAsset() external view returns (address asset_);

    /**
     *  @dev The amount of time the borrower has, after a payment is due, to make a payment before being in default.
     */
    function gracePeriod() external view returns (uint32 gracePeriod_);

    /**
     *  @dev The annualized interest rate (APR), in units of 1e18, (i.e. 1% is 0.01e18).
     */
    function interestRate() external view returns (uint256 interestRate_);

    /**
     *  @dev The rate charged at late payments.
     */
    function lateFeeRate() external view returns (uint256 lateFeeRate_);

    /**
     *  @dev The premium over the regular interest rate applied when paying late.
     */
    function lateInterestPremium() external view returns (uint256 lateInterestPremium_);

    /**
     *  @dev The lender of the Loan.
     */
    function lender() external view returns (address lender_);

    /**
     *  @dev The timestamp due date of the next payment.
     */
    function nextPaymentDueDate() external view returns (uint40 nextPaymentDueDate_);

    /**
     *  @dev The amount of time the borrower has, after the loan is called, to close the loan.
     */
    function noticePeriod() external view returns (uint32 noticePeriod_);

    /**
     *  @dev The saved original payment due date from a loan impairment.
     */
    function originalNextPaymentDueDate() external view returns (uint40 originalNextPaymentDueDate_);

    /**
     *  @dev The specified time between loan payments.
     */
    function paymentInterval() external view returns (uint32 paymentInterval_);

    /**
     *  @dev The address of the pending borrower.
     */
    function pendingBorrower() external view returns (address pendingBorrower_);

    /**
     *  @dev The address of the pending lender.
     */
    function pendingLender() external view returns (address pendingLender_);

    /**
     *  @dev The amount of principal owed (initially, the requested amount), which needs to be paid back.
     */
    function principal() external view returns (uint256 principal_);

}
