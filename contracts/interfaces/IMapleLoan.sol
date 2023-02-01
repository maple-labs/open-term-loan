// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleProxied } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";

import { IMapleLoanEvents }  from "./IMapleLoanEvents.sol";
import { IMapleLoanStorage } from "./IMapleLoanStorage.sol";

/// @title MapleLoan implements a primitive loan with additional functionality, and is intended to be proxied.
interface IMapleLoan is IMapleProxied, IMapleLoanEvents, IMapleLoanStorage {

    /**************************************************************************************************************************************/
    /*** State Changing Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev Accept the borrower role, must be called by pendingBorrower.
     */
    function acceptBorrower() external;

    /**
     *  @dev Accept the lender role, must be called by pendingLender.
     */
    function acceptLender() external;

    /**
     *  @dev    The lender called the loan, giving the borrower a notice period within which to return principal and pro-rata interest.
     *  @param  principalToReturn_  The minimum amount of principal the borrower must return.
     *  @return nextPaymentDueDate_ The payment due date for returning the principal and pro-rate interest to the lender.
     */
    function call(uint256 principalToReturn_) external returns (uint40 nextPaymentDueDate_);

    /**
     *  @dev   Draw down funds from the loan.
     *  @param amount_      The amount to draw down.
     *  @param destination_ The address to send the funds.
     */
    function drawdown(uint256 amount_, address destination_) external;

    /**
     *  @dev    Lend funds to the loan/borrower.
     *  @return fundsLent_ The amount funded.
     */
    function fund() external returns (uint256 fundsLent_);

    /**
     *  @dev    Fast forward the next payment due date to the current time.
     *          This enables the pool delegate to force a payment (or default).
     *  @return nextPaymentDueDate_ The new payment due date to result in the removal of the loan's impairment status.
     */
    function impair() external returns (uint40 nextPaymentDueDate_);

    /**
     *  @dev    Make a payment to the loan.
     *  @param  principalToReturn_ The amount of principal to return, to the lender to reduce future interest payments.
     *  @return interest_          The portion of the amount paying interest.
     *  @return lateInterest_      The portion of the amount paying late interest.
     */
    function makePayment(uint256 principalToReturn_) external returns (uint256 interest_, uint256 lateInterest_);

    /**
     *  @dev    Remove the loan's called status.
     *  @return nextPaymentDueDate_ The restored payment due date.
     */
    function removeCall() external returns (uint40 nextPaymentDueDate_);

    /**
     *  @dev    Remove the loan impairment by restoring the original payment due date.
     *  @return nextPaymentDueDate_ The restored payment due date.
     */
    function removeImpairment() external returns (uint40 nextPaymentDueDate_);

    /**
     *  @dev    Repossess collateral, and any funds, for a loan in default.
     *  @param  destination_      The address where the collateral and funds asset is to be sent, if any.
     *  @return fundsRepossessed_ The amount of funds asset repossessed.
     */
    function repossess(address destination_) external returns (uint256 fundsRepossessed_);

    /**
     *  @dev   Set the `pendingBorrower` to a new account.
     *  @param pendingBorrower_ The address of the new pendingBorrower.
     */
    function setPendingBorrower(address pendingBorrower_) external;

    /**
     *  @dev   Set the `pendingLender` to a new account.
     *  @param pendingLender_ The address of the new pendingLender.
     */
    function setPendingLender(address pendingLender_) external;

    /**
     *  @dev    Remove all token that is not `fundsAsset`.
     *  @param  token_       The address of the token contract.
     *  @param  destination_ The recipient of the token.
     *  @return skimmed_     The amount of token removed from the loan.
     */
    function skim(address token_, address destination_) external returns (uint256 skimmed_);

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev The Maple globals address
     */
    function globals() external view returns (address globals_);

    /**
     *  @dev    Return if the loan has been called.
     *  @return isCalled_ Whether the loan is called.
     */
    function isCalled() external view returns (bool isCalled_);

    /**
     *  @dev    Return if the loan has been impaired.
     *  @return isImpaired_ Whether the loan is impaired.
     */
    function isImpaired() external view returns (bool isImpaired_);

    /**
     *  @dev    Get the breakdown of the total payment needed to satisfy the next payment installment.
     *  @return interest_     The portion of the total amount that will go towards interest fees.
     *  @return lateInterest_ The portion of the total amount that will go towards late interest fees.
     */
    function nextPaymentBreakdown() external view returns (uint256 interest_, uint256 lateInterest_);

}
