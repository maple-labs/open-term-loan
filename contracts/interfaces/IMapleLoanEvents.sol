// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

/// @title IMapleLoanEvents defines the events for a MapleLoan.
interface IMapleLoanEvents {

    /**
     *  @dev   Borrower was accepted, and set to a new account.
     *  @param borrower_ The address of the new borrower.
     */
    event BorrowerAccepted(address indexed borrower_);

    /**
     *  @dev   Collateral was posted.
     *  @param amount_ The amount of collateral posted.
     */
    event CollateralPosted(uint256 amount_);

    /**
     *  @dev   Collateral was removed.
     *  @param amount_      The amount of collateral removed.
     *  @param destination_ The recipient of the collateral removed.
     */
    event CollateralRemoved(uint256 amount_, address indexed destination_);

    /**
     *  @dev   The loan was funded.
     *  @param lender_             The address of the lender.
     *  @param amount_             The amount funded.
     *  @param nextPaymentDueDate_ The due date of the next payment.
     */
    event Funded(address indexed lender_, uint256 amount_, uint256 nextPaymentDueDate_);

    /**
     *  @dev   Funds were claimed.
     *  @param amount_      The amount of funds claimed.
     *  @param destination_ The recipient of the funds claimed.
     */
    event FundsClaimed(uint256 amount_, address indexed destination_);

    /**
     *  @dev   Funds were drawn.
     *  @param amount_      The amount of funds drawn.
     *  @param destination_ The recipient of the funds drawn down.
     */
    event FundsDrawnDown(uint256 amount_, address indexed destination_);

    /**
     *  @dev   Funds were returned.
     *  @param amount_ The amount of funds returned.
     */
    event FundsReturned(uint256 amount_);

    /**
     *  @dev   Loan was initialized.
     *  @param globals_        The address of the globals contract.
     *  @param borrower_       The address of the borrower.
     *  @param feeManager_     The address of the entity responsible for calculating fees
     *  @param originationFee_ The fee paid by the borrower on loan origination.
     *  @param assets_         Array of asset addresses.
     *                          [0]: collateralAsset,
     *                          [1]: fundsAsset.
     *  @param termDetails_    Array of loan parameters:
     *                          [0]: gracePeriod,
     *                          [1]: paymentInterval,
     *                          [2]: payments,
     *  @param amounts_        Requested amounts:
     *                          [0]: collateralRequired,
     *                          [1]: principalRequested,
     *                          [2]: endingPrincipal.
     *  @param rates_          Fee parameters:
     *                          [0]: interestRate,
     *                          [1]: closingFeeRate,
     *                          [2]: lateFeeRate,
     *                          [3]: lateInterestPremium,
     *                          [5]: adminFeeRate.
     */
    event Initialized(
        address indexed globals_,
        address indexed borrower_,
        address indexed feeManager_,
        uint256 originationFee_,
        address[2] assets_,
        uint256[3] termDetails_,
        uint256[3] amounts_,
        uint256[5] rates_
    );

    /**
     *  @dev   Lender was accepted, and set to a new account.
     *  @param lender_ The address of the new lender.
     */
    event LenderAccepted(address indexed lender_);

    /**
     *  @dev   Loan was repaid early and closed.
     *  @param principalPaid_ The portion of the total amount that went towards principal.
     *  @param interestPaid_  The portion of the total amount that went towards interest.
     *  @param feesPaid_      The portion of the total amount that went towards fees.
     */
    event LoanClosed(uint256 principalPaid_, uint256 interestPaid_, uint256 feesPaid_);

    /**
     *  @dev   The terms of the refinance proposal were accepted.
     *  @param refinanceCommitment_ The hash of the refinancer, deadline, and calls proposed.
     *  @param refinancer_          The address that will execute the refinance.
     *  @param deadline_            The deadline for accepting the new terms.
     *  @param calls_               The individual calls for the refinancer contract.
     */
    event NewTermsAccepted(bytes32 refinanceCommitment_, address refinancer_, uint256 deadline_, bytes[] calls_);

    /**
     *  @dev   A refinance was proposed.
     *  @param refinanceCommitment_ The hash of the refinancer, deadline, and calls proposed.
     *  @param refinancer_          The address that will execute the refinance.
     *  @param deadline_            The deadline for accepting the new terms.
     *  @param calls_               The individual calls for the refinancer contract.
     */
    event NewTermsProposed(bytes32 refinanceCommitment_, address refinancer_, uint256 deadline_, bytes[] calls_);

    /**
     *  @dev   The terms of the refinance proposal were rejected.
     *  @param refinanceCommitment_ The hash of the refinancer, deadline, and calls proposed.
     *  @param refinancer_          The address that will execute the refinance.
     *  @param deadline_            The deadline for accepting the new terms.
     *  @param calls_               The individual calls for the refinancer contract.
     */
    event NewTermsRejected(bytes32 refinanceCommitment_, address refinancer_, uint256 deadline_, bytes[] calls_);

    /**
     *  @dev   The next payment due date was fastforwarded to block.timestamp, activating the grace period. This is in the case that the pool delegate wants to force a payment (or default).
     *  @param nextPaymentDueDate_ The new next payment due date.
     */
    event NextPaymentDueDateFastForwarded(uint256 nextPaymentDueDate_);

    /**
     *  @dev   Payments were made.
     *  @param principalPaid_ The portion of the total amount that went towards principal.
     *  @param interestPaid_  The portion of the total amount that went towards interest.
     *  @param fees_          The portion of the total amount that went towards fees.
     */
    event PaymentMade(uint256 principalPaid_, uint256 interestPaid_, uint256 fees_);

    /**
     *  @dev   Pending borrower was set.
     *  @param pendingBorrower_ Address that can accept the borrower role.
     */
    event PendingBorrowerSet(address pendingBorrower_);

    /**
     *  @dev   Pending lender was set.
     *  @param pendingLender_ Address that can accept the lender role.
     */
    event PendingLenderSet(address pendingLender_);

    /**
     *  @dev   The loan was in default and funds and collateral was repossessed by the lender.
     *  @param collateralRepossessed_ The amount of collateral asset repossessed.
     *  @param fundsRepossessed_      The amount of funds asset repossessed.
     *  @param destination_           The recipient of the collateral and funds, if any.
     */
    event Repossessed(uint256 collateralRepossessed_, uint256 fundsRepossessed_, address indexed destination_);

    /**
     *  @dev   Some token (neither fundsAsset nor collateralAsset) was removed from the loan.
     *  @param token_       The address of the token contract.
     *  @param amount_      The amount of token remove from the loan.
     *  @param destination_ The recipient of the token.
     */
    event Skimmed(address indexed token_, uint256 amount_, address indexed destination_);

}
