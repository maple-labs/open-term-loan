// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { MapleLoanHarness } from "./harnesses/MapleLoanHarness.sol";

import { MapleGlobalsMock, MockFactory } from "./mocks/Mock.sol";

contract TestBase is Test {

    address internal globals;
    address internal governor;
    address internal mockFactory;

    uint256 internal start;

    function setUp() public virtual {
        governor    = makeAddr("governor");
        globals     = address(new MapleGlobalsMock(governor));
        mockFactory = address(new MockFactory(globals));

        start = block.timestamp;
    }

    function createLoan(
        address borrower,
        address lender,
        address fundsAsset,
        uint32[3] memory termDetails,
        uint256[3] memory rates
    ) internal returns (address loan_) {
        MapleLoanHarness loan = new MapleLoanHarness();

        loan.__setBorrower(borrower);
        loan.__setLender(lender);
        loan.__setFactory(mockFactory);
        loan.__setFundsAsset(fundsAsset);
        loan.__setGracePeriod(termDetails[0]);
        loan.__setNoticePeriod(termDetails[1]);
        loan.__setPaymentInterval(termDetails[2]);
        loan.__setInterestRate(rates[0]);
        loan.__setLateFeeRate(rates[1]);
        loan.__setLateInterestPremium(rates[2]);

        return address(loan);
    }

}
