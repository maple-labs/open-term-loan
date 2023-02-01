// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IERC20 }                from "../modules/erc20/contracts/interfaces/IERC20.sol";
import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { IMapleLoan } from "./interfaces/IMapleLoan.sol";

import { IMapleGlobalsLike, ILenderLike, IMapleProxyFactoryLike } from "./interfaces/Interfaces.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

/*

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗    ██╗      ██████╗  █████╗ ███╗   ██╗    ██╗   ██╗██╗  ██╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝    ██║     ██╔═══██╗██╔══██╗████╗  ██║    ██║   ██║██║  ██║
    ██╔████╔██║███████║██████╔╝██║     █████╗      ██║     ██║   ██║███████║██╔██╗ ██║    ██║   ██║███████║
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝      ██║     ██║   ██║██╔══██║██║╚██╗██║    ╚██╗ ██╔╝╚════██║
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗    ███████╗╚██████╔╝██║  ██║██║ ╚████║     ╚████╔╝      ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝      ╚═══╝       ╚═╝

*/

// TODO: Update ASCII art.
// TODO: Reorder functions.
// TODO: Use error codes.
// TODO: Check order or impair and call without reverting in between.
// TODO: Consider safe casting from uint256 to uint32/uint40.
// TODO: Consider possibility of being called and impaired at the sme time (i.e. `isImpaired` and `isCalled`).
// TODO: Issue with (re)impairing or (re)calling (or a mix) with losing the original next payment due date.
// TODO: Consider having a `lastPaymentDate`, `callDate`, and `impairDate` with a virtual `nextPaymentDueDate` so that we no longer
//       have to keep track of an "ugly" `originalNextPaymentDueDate`.

/// @title MapleLoan implements a primitive loan with additional functionality, and is intended to be proxied.
contract MapleLoan is IMapleLoan, MapleProxiedInternals, MapleLoanStorage {

    uint256 private constant HUNDRED_PERCENT = 1e18;

    // NOTE: The following functions already check for paused state in the poolManager/loanManager, therefore no need to check here.
    // * acceptNewTerms
    // * call
    // * fund
    // * impair
    // * removeImpairment
    // * repossess
    // * setPendingLender -> Not implemented
    modifier whenProtocolNotPaused() {
        require(!IMapleGlobalsLike(globals()).protocolPaused(), "L:PROTOCOL_PAUSED");
        _;
    }

    /**************************************************************************************************************************************/
    /*** Administrative Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    function migrate(address migrator_, bytes calldata arguments_) external override {
        require(msg.sender == _factory(),        "ML:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "ML:M:FAILED");
    }

    function setImplementation(address newImplementation_) external override {
        require(msg.sender == _factory(),               "ML:SI:NOT_FACTORY");
        require(_setImplementation(newImplementation_), "ML:SI:FAILED");
    }

    function upgrade(uint256 toVersion_, bytes calldata arguments_) external override whenProtocolNotPaused {
        require(msg.sender == borrower, "ML:U:NOT_BORROWER");

        emit Upgraded(toVersion_, arguments_);

        IMapleProxyFactory(_factory()).upgradeInstance(toVersion_, arguments_);
    }

    /**************************************************************************************************************************************/
    /*** Borrow Functions                                                                                                               ***/
    /**************************************************************************************************************************************/

    function acceptBorrower() external override whenProtocolNotPaused {
        require(msg.sender == pendingBorrower, "ML:AB:NOT_PENDING_BORROWER");

        delete pendingBorrower;

        emit BorrowerAccepted(borrower = msg.sender);
    }

    function drawdown(uint256 amount_, address destination_) external override whenProtocolNotPaused {
        require(msg.sender == borrower, "ML:D:NOT_BORROWER");

        emit FundsDrawnDown(amount_, destination_);

        require(ERC20Helper.transfer(fundsAsset, destination_, amount_), "ML:D:TRANSFER_FAILED");
    }

    function makePayment(uint256 principalToReturn_)
        external override whenProtocolNotPaused returns (uint256 interest_, uint256 lateInterest_) {
        // If the loan is called, the principal being returned must be greater than the portion called.
        // TODO: Better error, but error codes would be better.
        require(principalToReturn_ >= calledPrincipal, "ML:MP:INSUFFICIENT_FOR_CALL");

        ( interest_, lateInterest_ ) = nextPaymentBreakdown();

        uint256 total = principalToReturn_ + interest_ + lateInterest_;

        // TODO: Merge the transfers into one
        // TODO: Cache `IERC20(fundsAsset).balanceOf(address(this))`

        if (IERC20(fundsAsset).balanceOf(address(this)) < total) {
            require(
                ERC20Helper.transferFrom(fundsAsset, msg.sender, address(this), total - IERC20(fundsAsset).balanceOf(address(this))),
                "ML:MP:TRANSFER_FROM_FAILED"
            );
        }

        // NOTE: a payment clears loan impairment, and this is cheaper to always do.
        delete originalNextPaymentDueDate;

        if (principalToReturn_ == principal) {
            _clearLoanAccounting();
            emit PrincipalReturned(principalToReturn_, 0);
        } else if (principalToReturn_ > uint256(0)) {
            delete calledPrincipal;
            emit PrincipalReturned(principalToReturn_, principal -= principalToReturn_);
        }

        uint256 previousPaymentDueDate_ = nextPaymentDueDate;

        emit PaymentMade(lender, principalToReturn_, interest_, lateInterest_);

        require(ERC20Helper.transfer(fundsAsset, lender, total), "ML:MP:TRANSFER_FAILED");

        ILenderLike(lender).claim(
            principalToReturn_,
            interest_ + lateInterest_,
            previousPaymentDueDate_,
            // NOTE: With this `nextPaymentDueDate` this way, a borrower can never overpay interest before closing (even partially) a loan.
            // Payment Due Date always `paymentInterval` after last payment.
            uint256(nextPaymentDueDate = uint40(block.timestamp + paymentInterval))  // TODO: This set iss wrong if loan is being closed.
        );
    }

    function setPendingBorrower(address pendingBorrower_) external override {
        require(msg.sender == borrower,                                    "ML:SPB:NOT_BORROWER");
        require(IMapleGlobalsLike(globals()).isBorrower(pendingBorrower_), "ML:SPB:INVALID_BORROWER");

        emit PendingBorrowerSet(pendingBorrower = pendingBorrower_);
    }

    /**************************************************************************************************************************************/
    /*** Lend Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function acceptLender() external override whenProtocolNotPaused {
        require(msg.sender == pendingLender, "ML:AL:NOT_PENDING_LENDER");

        delete pendingLender;

        emit LenderAccepted(lender = msg.sender);
    }

    function call(uint256 principalToReturn_) external override returns (uint40 nextPaymentDueDate_) {
        require(msg.sender == lender,            "ML:C:NOT_LENDER");
        require(principalToReturn_ <= principal, "ML:C:INSUFFICIENT_PRINCIPAL");
        require(calledPrincipal == uint256(0),   "ML:C:ALREADY_CALLED");          // TODO: Consider allowing call when already called.

        // TODO: Either cache originalNextPaymentDueDate or inline it in the _min call below, to save gas.
        originalNextPaymentDueDate = nextPaymentDueDate;  // Store the existing payment due date to enable reversion.

        emit Called(
            calledPrincipal = principalToReturn_,
            // If the loan is late, do not change the payment due date.
            nextPaymentDueDate = nextPaymentDueDate_ = uint40(
                _min(
                    block.timestamp + noticePeriod,
                    originalNextPaymentDueDate
                )
            )
        );
    }

    function fund() external override returns (uint256 fundsLent_) {
        address lender_ = lender;

        // TODO: Consider allowing setting lender if undefined, to allow any lender to fund.
        require(msg.sender == lender_, "ML:F:NOT_LENDER");

        // Can only fund loan if there are payments remaining (as defined by the initialization)
        // and no payment is due yet (as set by a funding).
        require(nextPaymentDueDate == 0, "ML:F:LOAN_ACTIVE");

        emit Funded(
            lender_,
            fundsLent_ = principal,
            nextPaymentDueDate = uint40(block.timestamp + paymentInterval)
        );

        require(ERC20Helper.transferFrom(fundsAsset, msg.sender, address(this), fundsLent_), "ML:F:TRANSFER_FROM_FAILED");
    }

    function impair() external override returns (uint40 nextPaymentDueDate_) {
        require(msg.sender == lender, "ML:I:NOT_LENDER");

        // TODO: Either cache originalNextPaymentDueDate or inline it in the _min call below, to save gas.
        originalNextPaymentDueDate = nextPaymentDueDate;  // Store the existing payment due date to enable reversion.

        emit Impaired(
            // If the loan is late, do not change the payment due date.
            nextPaymentDueDate = nextPaymentDueDate_ = uint40(
                _min(
                    block.timestamp,
                    originalNextPaymentDueDate
                )
            )
        );
    }

    function removeImpairment() external override returns (uint40 nextPaymentDueDate_) {
        uint40 originalNextPaymentDueDate_ = originalNextPaymentDueDate;

        require(msg.sender == lender,                           "ML:RI:NOT_LENDER");
        require(originalNextPaymentDueDate_ != 0,               "ML:RI:NOT_IMPAIRED");
        require(block.timestamp <= originalNextPaymentDueDate_, "ML:RI:PAST_DATE");     // TODO: Is this still necessary?

        emit ImpairmentRemoved(nextPaymentDueDate = nextPaymentDueDate_ = originalNextPaymentDueDate);

        delete originalNextPaymentDueDate;
    }

    // TODO: Check no issue with overriding originalNextPaymentDueDate alongside impair calls
    function removeCall() external override returns (uint40 nextPaymentDueDate_) {
        require(msg.sender == lender,          "ML:RC:NOT_LENDER");
        require(calledPrincipal != uint256(0), "ML:RC:NOT_CALLED");

        emit CallRemoved(nextPaymentDueDate = nextPaymentDueDate_ = originalNextPaymentDueDate);

        delete originalNextPaymentDueDate;
        delete calledPrincipal;
    }

    function repossess(address destination_) external override returns (uint256 fundsRepossessed_) {
        require(msg.sender == lender, "ML:R:NOT_LENDER");

        uint256 nextPaymentDueDate_ = nextPaymentDueDate;

        require(
            // TODO: This date is incorrect if the loan is called. Consider a function for complete logic, or better date storage variables.
            nextPaymentDueDate_ != uint256(0) && (block.timestamp > nextPaymentDueDate_ + gracePeriod),
            "ML:R:NOT_IN_DEFAULT"
        );

        _clearLoanAccounting();

        address fundsAsset_ = fundsAsset;

        emit Repossessed(fundsRepossessed_, destination_);

        // Either there are no funds to repossess, or the transfer of the funds succeeds.
        require(
            IERC20(fundsAsset_).balanceOf(address(this)) == uint256(0) ||
            ERC20Helper.transfer(fundsAsset_, destination_, fundsRepossessed_),
            "ML:R:F_TRANSFER_FAILED"
        );
    }

    function setPendingLender(address pendingLender_) external override {
        require(msg.sender == lender, "ML:SPL:NOT_LENDER");

        emit PendingLenderSet(pendingLender = pendingLender_);
    }

    /**************************************************************************************************************************************/
    /*** Miscellaneous Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function skim(address token_, address destination_) external override whenProtocolNotPaused returns (uint256 skimmed_) {
        require((msg.sender == borrower) || (msg.sender == lender), "ML:S:NOT_AUTHORIZED");
        require(token_ != fundsAsset,                               "ML:S:FUNDS_ASSET");

        skimmed_ = IERC20(token_).balanceOf(address(this));

        require(skimmed_ > uint256(0), "ML:S:NO_TOKEN_TO_SKIM");

        emit Skimmed(token_, skimmed_, destination_);

        require(ERC20Helper.transfer(token_, destination_, skimmed_), "ML:S:TRANSFER_FAILED");
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function nextPaymentBreakdown() public view override returns (uint256 interest_, uint256 lateInterest_) {
        ( interest_, lateInterest_ )
            = _getPaymentBreakdown(
                principal,
                interestRate,
                lateInterestPremium,
                lateFeeRate,
                uint32(block.timestamp - (nextPaymentDueDate - paymentInterval)),                        // Time since last payment.
                uint32(block.timestamp > nextPaymentDueDate ? block.timestamp - nextPaymentDueDate : 0)  // Time since payment due date.
            );
    }

    /**************************************************************************************************************************************/
    /*** State View Functions                                                                                                           ***/
    /**************************************************************************************************************************************/

    function factory() external view override returns (address factory_) {
        return _factory();
    }

    function globals() public view override returns (address globals_) {
        globals_ = IMapleProxyFactoryLike(_factory()).mapleGlobals();
    }

    function implementation() external view override returns (address implementation_) {
        return _implementation();
    }

    function isCalled() public view override returns (bool isCalled_) {
        isCalled_ = calledPrincipal != uint256(0);
    }

    function isImpaired() public view override returns (bool isImpaired_) {
        isImpaired_ = (originalNextPaymentDueDate != uint40(0)) && !isCalled();
    }

    /**************************************************************************************************************************************/
    /*** Internal General Functions                                                                                                     ***/
    /**************************************************************************************************************************************/

    /// @dev Clears all state variables to end a loan, but keep borrower and lender withdrawal functionality intact.
    function _clearLoanAccounting() internal {
        delete gracePeriod;
        delete noticePeriod;
        delete paymentInterval;

        delete nextPaymentDueDate;
        delete originalNextPaymentDueDate;

        delete calledPrincipal;
        delete principal;

        delete interestRate;
        delete lateFeeRate;
        delete lateInterestPremium;
    }

    /**************************************************************************************************************************************/
    /*** Internal Pure Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    /// @dev Returns an amount by applying an annualized and scaled interest rate, to a principal, over an interval of time.
    function _getPaymentBreakdown(
        uint256 principal_,
        uint256 interestRate_,
        uint256 lateInterestPremium_,
        uint256 lateFeeRate_,
        uint32 interval_,
        uint32 lateInterval_
    )
        internal pure returns (uint256 interest_, uint256 lateInterest_)
    {
        interest_ = _getProRatedAmount(principal_, interestRate_, interval_);

        if (lateInterval_ == 0) return (interest_, 0);

        lateInterest_ =
            _getProRatedAmount(principal_, interestRate_ + lateInterestPremium_, lateInterval_) +
            ((principal_ * lateFeeRate_) / HUNDRED_PERCENT);
    }

    function _getProRatedAmount(uint256 amount_, uint256 rate_, uint32 interval_) internal pure returns (uint256 proRatedAmount_) {
        proRatedAmount_ = (amount_ * rate_ * interval_) / (uint256(365 days) * HUNDRED_PERCENT);
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 min_) {
        min_ = a_ < b_ ? a_ : b_;
    }

}
