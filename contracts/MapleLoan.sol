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

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝
    ██╔████╔██║███████║██████╔╝██║     █████╗
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝

     ██████╗ ██████╗ ███████╗███╗   ██╗    ████████╗███████╗██████╗ ███╗   ███╗    ██╗      ██████╗  █████╗ ███╗   ██╗    ██╗   ██╗ ██╗
    ██╔═══██╗██╔══██╗██╔════╝████╗  ██║    ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║    ██║     ██╔═══██╗██╔══██╗████╗  ██║    ██║   ██║███║
    ██║   ██║██████╔╝█████╗  ██╔██╗ ██║       ██║   █████╗  ██████╔╝██╔████╔██║    ██║     ██║   ██║███████║██╔██╗ ██║    ██║   ██║╚██║
    ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║       ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║    ██║     ██║   ██║██╔══██║██║╚██╗██║    ╚██╗ ██╔╝ ██║
    ╚██████╔╝██║     ███████╗██║ ╚████║       ██║   ███████╗██║  ██║██║ ╚═╝ ██║    ███████╗╚██████╔╝██║  ██║██║ ╚████║     ╚████╔╝  ██║
     ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝      ╚═══╝   ╚═╝

*/

// TODO: Use error codes.
// TODO: Consider safe casting from uint256 to uint32/uint40.

/// @title MapleLoan implements an open term loan, and is intended to be proxied.
contract MapleLoan is IMapleLoan, MapleProxiedInternals, MapleLoanStorage {

    // TODO: Think about using `1e6` for all percentage variables.
    uint256 internal constant HUNDRED_PERCENT = 1e18;

    // NOTE: The following functions already check for paused state in the poolManager/loanManager, therefore no need to check here.
    // * call
    // * fund
    // * impair
    // * removeCall
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

    function makePayment(uint256 principalToReturn_)
        external override whenProtocolNotPaused returns (uint256 interest_, uint256 lateInterest_) {
        // If the loan is called, the principal being returned must be greater than the portion called.
        // TODO: Better error, but error codes would be better.
        require(principalToReturn_ >= calledPrincipal, "ML:MP:INSUFFICIENT_FOR_CALL");

        ( interest_, lateInterest_ ) = paymentBreakdown();

        uint256 total = principalToReturn_ + interest_ + lateInterest_;

        // TODO: Merge the transfers into one
        // TODO: Cache `IERC20(fundsAsset).balanceOf(address(this))`

        if (IERC20(fundsAsset).balanceOf(address(this)) < total) {
            require(
                ERC20Helper.transferFrom(fundsAsset, msg.sender, address(this), total - IERC20(fundsAsset).balanceOf(address(this))),
                "ML:MP:TRANSFER_FROM_FAILED"
            );
        }

        if (principalToReturn_ == principal) {
            _clearLoanAccounting();
            emit PrincipalReturned(principalToReturn_, 0);
        } else {
            // NOTE: a payment clears loan impair and called status, and this is cheaper to always do.
            delete dateCalled;
            delete dateImpaired;
            delete calledPrincipal;

            if (principalToReturn_ != uint256(0)) {
                emit PrincipalReturned(principalToReturn_, principal -= principalToReturn_);
            }
        }

        datePaid = uint40(block.timestamp);

        uint40 paymentDueDate_ = paymentDueDate();

        emit PaymentMade(lender, principalToReturn_, interest_, lateInterest_, paymentDueDate_, defaultDate());

        require(ERC20Helper.transfer(fundsAsset, lender, total), "ML:MP:TRANSFER_FAILED");

        ILenderLike(lender).claim(
            principalToReturn_,
            interest_ + lateInterest_,
            paymentDueDate_
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

    // TODO: Should revert if the loan has not yet been funded.
    function call(uint256 principalToReturn_) external override returns (uint40 paymentDueDate_) {
        require(msg.sender == lender,            "ML:C:NOT_LENDER");
        require(principalToReturn_ <= principal, "ML:C:INSUFFICIENT_PRINCIPAL");

        // TODO: Investigate if we should add a check for if the loan is already called.

        dateCalled = uint40(block.timestamp);

        emit Called(
            calledPrincipal = principalToReturn_,
            paymentDueDate_ = paymentDueDate(),
            defaultDate()
        );
    }

    // TODO: Solve for cases where loan is/isn't funded, and closed.
    function fund() external override returns (uint256 fundsLent_, uint40 paymentDueDate_) {
        require(msg.sender == lender, "ML:F:NOT_LENDER");
        require(dateFunded == 0,      "ML:F:LOAN_ACTIVE");

        dateFunded = uint40(block.timestamp);

        emit Funded(
            fundsLent_      = principal,
            paymentDueDate_ = paymentDueDate(),
            defaultDate()
        );

        require(ERC20Helper.transferFrom(fundsAsset, msg.sender, borrower, fundsLent_), "ML:F:TRANSFER_FROM_FAILED");
    }

    function impair() external override returns (uint40 paymentDueDate_, uint40 defaultDate_) {
        require(msg.sender == lender, "ML:I:NOT_LENDER");
        require(dateFunded != 0,      "ML:I:LOAN_INACTIVE");
        require(dateImpaired == 0,    "ML:I:ALREADY_IMPAIRED");  // TODO: Investigate if this is necessary

        dateImpaired = uint40(block.timestamp);

        emit Impaired(
            paymentDueDate_ = paymentDueDate(),
            defaultDate_    = defaultDate()
        );
    }

    function removeCall() external override returns (uint40 paymentDueDate_) {
        require(msg.sender == lender,    "ML:RC:NOT_LENDER");
        require(dateCalled == uint40(0), "ML:RI:NOT_CALLED");

        delete dateCalled;

        emit CallRemoved(
            paymentDueDate_ = paymentDueDate(),
            defaultDate()
        );
    }

    function removeImpairment() external override returns (uint40 paymentDueDate_, uint40 defaultDate_) {
        require(msg.sender == lender, "ML:RI:NOT_LENDER");
        require(dateImpaired != 0,    "ML:RI:NOT_IMPAIRED");

        delete dateImpaired;

        emit ImpairmentRemoved(
            paymentDueDate_ = paymentDueDate(),
            defaultDate_    = defaultDate()
        );
    }

    function repossess(address destination_) external override returns (uint256 fundsRepossessed_) {
        require(msg.sender == lender, "ML:R:NOT_LENDER");
        require(isInDefault(),        "ML:R:NOT_IN_DEFAULT");

        _clearLoanAccounting();

        address fundsAsset_ = fundsAsset;

        emit Repossessed(
            fundsRepossessed_ = IERC20(fundsAsset_).balanceOf(address(this)),
            destination_
        );

        // Either there are no funds to repossess, or the transfer of the funds succeeds.
        require(fundsRepossessed_ == 0 || ERC20Helper.transfer(fundsAsset_, destination_, fundsRepossessed_), "ML:R:TRANSFER_FAILED");
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

    function defaultDate() public view override returns (uint40 paymentDefaultDate_) {
        ( uint40 callDefaultDate_, uint40 impairedDefaultDate_, uint40 normalPaymentDueDate_ ) = _defaultDates();

        paymentDefaultDate_ = _minDate(callDefaultDate_, _minDate(impairedDefaultDate_, normalPaymentDueDate_));
    }

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
        isCalled_ = dateCalled != uint40(0);
    }

    function isImpaired() public view override returns (bool isImpaired_) {
        isImpaired_ = dateImpaired != uint40(0);
    }

    function isInDefault() public view override returns (bool isInDefault_) {
        isInDefault_ = block.timestamp > defaultDate();
    }

    function paymentBreakdown() public view override returns (uint256 interest_, uint256 lateInterest_) {
        uint40 paymentDueDate_   = paymentDueDate();
        uint40 paidOrFundedDate_ = _maxDate(datePaid, dateFunded);

        bool isLate_ = block.timestamp > paymentDueDate_;

        ( interest_, lateInterest_ ) = _getPaymentBreakdown(
            principal,
            interestRate,
            lateInterestPremium,
            lateFeeRate,
            uint32(isLate_ ? paymentDueDate_ - paidOrFundedDate_ : block.timestamp - paidOrFundedDate_),  // "Current" interval
            uint32(isLate_ ? block.timestamp - paymentDueDate_   : 0)                                     // Late interval
        );
    }

    function paymentDueDate() public view override returns (uint40 paymentDueDate_) {
        ( uint40 callDueDate_, uint40 impairedDueDate_, uint40 normalDueDate_ ) = _dueDates();

        paymentDueDate_ = _minDate(callDueDate_, _minDate(impairedDueDate_, normalDueDate_));
    }

    /**************************************************************************************************************************************/
    /*** Internal Helper Functions                                                                                                      ***/
    /**************************************************************************************************************************************/

    /// @dev Clears all state variables to end a loan, but keep borrower and lender withdrawal functionality intact.
    function _clearLoanAccounting() internal {
        delete gracePeriod;
        delete noticePeriod;
        delete paymentInterval;

        delete dateCalled;
        delete datePaid;
        delete dateFunded;
        delete dateImpaired;

        delete calledPrincipal;
        delete principal;

        delete interestRate;
        delete lateFeeRate;
        delete lateInterestPremium;
    }

    /**************************************************************************************************************************************/
    /*** Internal View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function _dueDates() internal view returns (uint40 callDueDate_, uint40 impairedDueDate_, uint40 normalDueDate_) {
        uint40 dateFunded_ = dateFunded;

        require(dateFunded_ != uint40(0), "ML:DD:INACTIVE");

        uint40 dateCalled_   = dateCalled;
        uint40 dateImpaired_ = dateImpaired;
        uint40 datePaid_     = datePaid;

        callDueDate_     = (dateCalled_   != uint40(0)) ? dateCalled_ + noticePeriod : 0;
        impairedDueDate_ = (dateImpaired_ != uint40(0)) ? dateImpaired_              : 0;

        normalDueDate_ = _maxDate(dateFunded_, datePaid_) + paymentInterval;
    }

    function _defaultDates() internal view returns (uint40 callDefaultDate_, uint40 impairedDefaultDate_, uint40 normalDefaultDate_) {
        uint40 dateFunded_ = dateFunded;

        require(dateFunded_ != uint40(0), "ML:DD:INACTIVE");

        uint40 dateCalled_   = dateCalled;
        uint40 dateImpaired_ = dateImpaired;
        uint40 datePaid_     = datePaid;

        callDefaultDate_     = (dateCalled_   != uint40(0)) ? dateCalled_   + noticePeriod : 0;
        impairedDefaultDate_ = (dateImpaired_ != uint40(0)) ? dateImpaired_ + gracePeriod  : 0;

        normalDefaultDate_ = _maxDate(dateFunded_, datePaid_) + paymentInterval + gracePeriod;
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

    function _maxDate(uint40 a_, uint40 b_) internal pure returns (uint40 max_) {
        max_ = a_ == uint40(0) ? b_ : b_ == uint40(0) ? a_ : a_ > b_ ? a_ : b_;
    }

    function _minDate(uint40 a_, uint40 b_) internal pure returns (uint40 min_) {
        min_ = a_ == uint40(0) ? b_ : b_ == uint40(0) ? a_ : a_ < b_ ? a_ : b_;
    }

}
