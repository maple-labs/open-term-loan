// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IERC20 } from "../modules/erc20/contracts/interfaces/IERC20.sol";

import { IMapleRefinancer } from "./interfaces/IMapleRefinancer.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

/*

    ██████╗ ███████╗███████╗██╗███╗   ██╗ █████╗ ███╗   ██╗ ██████╗███████╗██████╗
    ██╔══██╗██╔════╝██╔════╝██║████╗  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝██╔══██╗
    ██████╔╝█████╗  █████╗  ██║██╔██╗ ██║███████║██╔██╗ ██║██║     █████╗  ██████╔╝
    ██╔══██╗██╔══╝  ██╔══╝  ██║██║╚██╗██║██╔══██║██║╚██╗██║██║     ██╔══╝  ██╔══██╗
    ██║  ██║███████╗██║     ██║██║ ╚████║██║  ██║██║ ╚████║╚██████╗███████╗██║  ██║
    ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝

*/

// TODO: Update ASCII art
// TODO: `decreasePrincipal` and `increasePrincipal` not fully developed yet with the loan and loan manager.
// TODO: Add option for refinancing the delegate service fees?
// TODO: What happens to the platform service fee when a loan is refinanced? When (if ever) is it updated?

/// @title Refinancer uses storage from a MapleLoan defined by MapleLoanStorage.
contract MapleRefinancer is IMapleRefinancer, MapleLoanStorage {

    function decreasePrincipal(uint256 amount_) external override {
        principal -= amount_;

        emit PrincipalDecreased(amount_);
    }

    function increasePrincipal(uint256 amount_) external override {
        principal += amount_;

        emit PrincipalIncreased(amount_);
    }

    function setGracePeriod(uint32 gracePeriod_) external override {
        emit GracePeriodSet(gracePeriod = gracePeriod_);
    }

    function setInterestRate(uint64 interestRate_) external override {
        emit InterestRateSet(interestRate = interestRate_);
    }

    function setLateFeeRate(uint64 lateFeeRate_) external override {
        emit LateFeeRateSet(lateFeeRate = lateFeeRate_);
    }

    function setLateInterestPremium(uint64 lateInterestPremium_) external override {
        emit LateInterestPremiumSet(lateInterestPremium = lateInterestPremium_);
    }

    function setNoticePeriod(uint32 noticePeriod_) external override {
        emit NoticePeriodSet(noticePeriod = noticePeriod_);
    }

    function setPaymentInterval(uint32 paymentInterval_) external override {
        require(paymentInterval_ != 0, "R:SPI:ZERO_AMOUNT");

        emit PaymentIntervalSet(paymentInterval = paymentInterval_);
    }

}
