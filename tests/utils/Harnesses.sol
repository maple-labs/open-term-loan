// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { MapleLoan } from "../../contracts/MapleLoan.sol";

contract MapleLoanHarness is MapleLoan {

    /**************************************************************************************************************************************/
    /*** Mutating Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function __clearLoanAccounting() external {
        _clearLoanAccounting();
    }

    /**************************************************************************************************************************************/
    /*** State Setters                                                                                                                  ***/
    /**************************************************************************************************************************************/

    // TODO: Revert on failed `uint` casts.

    function __setBorrower(address borrower_) external {
        borrower = borrower_;
    }

    function __setCalledPrincipal(uint256 calledPrincipal_) external {
        calledPrincipal = calledPrincipal_;
    }

    function __setDateCalled(uint256 dateCalled_) external {
        dateCalled = uint40(dateCalled_);
    }

    function __setDateFunded(uint256 dateFunded_) external {
        dateFunded = uint40(dateFunded_);
    }

    function __setDateImpaired(uint256 dateImpaired_) external {
        dateImpaired = uint40(dateImpaired_);
    }

    function __setDatePaid(uint256 datePaid_) external {
        datePaid = uint40(datePaid_);
    }

    function __setFactory(address factory_) external {
        _setFactory(factory_);
    }

    function __setFundsAsset(address fundsAsset_) external {
        fundsAsset = fundsAsset_;
    }

    function __setGracePeriod(uint256 gracePeriod_) external {
        gracePeriod = uint32(gracePeriod_);
    }

    function __setImplementation(address implementation_) external {
        _setImplementation(implementation_);
    }

    function __setInterestRate(uint256 interestRate_) external {
        interestRate = interestRate_;
    }

    function __setLateFeeRate(uint256 lateFeeRate_) external {
        lateFeeRate = lateFeeRate_;
    }

    function __setLateInterestPremium(uint256 lateInterestPremium_) external {
        lateInterestPremium = lateInterestPremium_;
    }

    function __setLender(address lender_) external {
        lender = lender_;
    }

    function __setNoticePeriod(uint256 noticePeriod_) external {
        noticePeriod = uint32(noticePeriod_);
    }

    function __setPaymentInterval(uint256 paymentInterval_) external {
        paymentInterval = uint32(paymentInterval_);
    }

    function __setPendingBorrower(address pendingBorrower_) external {
        pendingBorrower = pendingBorrower_;
    }

    function __setPendingLender(address pendingLender_) external {
        pendingLender = pendingLender_;
    }

    function __setPrincipal(uint256 principal_) external {
        principal = principal_;
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function __dueDates() external view returns (uint256 callDueDate_, uint256 impairedDueDate_, uint256 normalDueDate_) {
        return _dueDates();
    }

    function __defaultDates() external view returns (uint256 callDefaultDate_, uint256 impairedDefaultDate_, uint256 normalDefaultDate_) {
        return _defaultDates();
    }

    function __getCallDefaultDate(uint256 callDueDate_) external pure returns (uint256 defaultDate_) {
        defaultDate_ = _getCallDefaultDate(uint40(callDueDate_));
    }

    function __getCallDueDate(uint256 dateCalled_, uint256 noticePeriod_) external pure returns (uint256 dueDate_) {
        dueDate_ = _getCallDueDate(uint40(dateCalled_), uint32(noticePeriod_));
    }

    function __getImpairedDefaultDate(uint256 impairedDueDate_, uint256 gracePeriod_) external pure returns (uint256 defaultDate_) {
        defaultDate_ = _getImpairedDefaultDate(uint40(impairedDueDate_), uint32(gracePeriod_));
    }

    function __getImpairedDueDate(uint256 dateImpaired_) external pure returns (uint256 dueDate_) {
        dueDate_ = _getImpairedDueDate(uint40(dateImpaired_));
    }

    function __getNormalDefaultDate(uint256 normalDueDate_, uint256 gracePeriod_) external pure returns (uint256 defaultDate_) {
        defaultDate_ = _getNormalDefaultDate(uint40(normalDueDate_), uint32(gracePeriod_));
    }

    function __getNormalDueDate(uint256 dateFunded_, uint256 datePaid_, uint256 paymentInterval_) external pure returns (uint256 dueDate_) {
        dueDate_ = _getNormalDueDate(uint40(dateFunded_), uint40(datePaid_), uint32(paymentInterval_));
    }

    /**************************************************************************************************************************************/
    /*** Pure Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function __getPaymentBreakdown(
        uint256 principal_,
        uint256 interestRate_,
        uint256 lateInterestPremium_,
        uint256 lateFeeRate_,
        uint256 interval_,
        uint256 lateInterval_
    )
        external pure returns (uint256 interest_, uint256 lateInterest_)
    {
        return _getPaymentBreakdown(principal_, interestRate_, lateInterestPremium_, lateFeeRate_, uint32(interval_), uint32(lateInterval_));
    }

    function __getProRatedAmount(uint256 amount_, uint256 rate_, uint32 interval_) external pure returns (uint256 proRatedAmount_) {
        return _getProRatedAmount(amount_, rate_, interval_);
    }

    function __maxDate(uint256 a_, uint256 b_) external pure returns (uint256 max_) {
        max_ = _maxDate(uint40(a_), uint40(b_));
    }

    function __minDate(uint256 a_, uint256 b_) external pure returns (uint256 min_) {
        min_ = _minDate(uint40(a_), uint40(b_));
    }

    function __minDate(uint256 a_, uint256 b_, uint256 c_) external pure returns (uint256 min_) {
        min_ = _minDate(uint40(a_), uint40(b_), uint40(c_));
    }

}
