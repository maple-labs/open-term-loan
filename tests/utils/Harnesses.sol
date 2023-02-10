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
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function __dueDates() external view returns (uint256 callDueDate_, uint256 impairedDueDate_, uint256 normalDueDate_) {
        return _dueDates();
    }

    function __defaultDates() external view returns (uint256 callDefaultDate_, uint256 impairedDefaultDate_, uint256 normalDefaultDate_) {
        return _defaultDates();
    }

    /**************************************************************************************************************************************/
    /*** State Setters                                                                                                                  ***/
    /**************************************************************************************************************************************/

    function __setBorrower(address borrower_) external {
        borrower = borrower_;
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

    function __setLender(address lender_) external {
        lender = lender_;
    }

    function __setFactory(address factory_) external {
        _setFactory(factory_);
    }

    function __setFundsAsset(address fundsAsset_) external {
        fundsAsset = fundsAsset_;
    }

    function __setGracePeriod(uint256 gracePeriod_) external {
        gracePeriod = uint32(gracePeriod_);  // TODO: Decide if safe casting a concern for testing?
    }

    function __setNoticePeriod(uint256 noticePeriod_) external {
        noticePeriod = uint32(noticePeriod_);  // TODO: Decide if safe casting a concern for testing?
    }

    function __setPaymentInterval(uint256 paymentInterval_) external {
        paymentInterval = uint32(paymentInterval_);  // TODO: Decide if safe casting a concern for testing?
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

    function __setPrincipal(uint256 principal_) external {
        principal = principal_;
    }

    /**************************************************************************************************************************************/
    /*** Pure Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function __getPaymentBreakdown(
        uint256 principal_,
        uint256 interestRate_,
        uint256 lateInterestPremium_,
        uint256 lateFeeRate_,
        uint32 interval_,
        uint32 lateInterval_
    )
        external pure returns (uint256 interest_, uint256 lateInterest_)
    {
        return _getPaymentBreakdown(principal_, interestRate_, lateInterestPremium_, lateFeeRate_, interval_, lateInterval_);
    }

    function __getProRatedAmount(uint256 amount_, uint256 rate_, uint32 interval_) external pure returns (uint256 proRatedAmount_) {
        return _getProRatedAmount(amount_, rate_, interval_);
    }

}
