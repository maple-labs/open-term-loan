// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../../modules/forge-std/src/Test.sol";

import { MockERC20 } from "../../modules/erc20/contracts/test/mocks/MockERC20.sol";

contract MockFactory {

    address public mapleGlobals;

    constructor(address mapleGlobals_) {
        mapleGlobals = mapleGlobals_;
    }

}

contract MockGlobals {

    bool public protocolPaused;

    function __setProtocolPaused(bool paused_) external {
        protocolPaused = paused_;
    }

}

contract MockLender is Test {

    bool internal assertClaim;
    bool internal expectedClaim;
    bool internal expectedClaimValues;

    uint256 internal expectedPrincipal;
    uint256 internal expectedInterest;
    uint256 internal expectedPaymentDueDate;

    function claim(uint256 principal_, uint256 interest_, uint40 paymentDueDate_) external {
        if (!assertClaim) return;

        assertTrue(expectedClaim);

        if (!expectedClaimValues) return;

        assertEq(principal_,      expectedPrincipal);
        assertEq(interest_,       expectedInterest);
        assertEq(paymentDueDate_, expectedPaymentDueDate);
    }

    function __assertClaim(bool assert_) public {
        assertClaim = assert_;
    }

    function __expectedClaim(bool expect_) public {
        __assertClaim(true);
        expectedClaim = expect_;
    }

    function __expectedClaim(uint256 principal_, uint256 interest_, uint40 paymentDueDate_) external {
        __expectedClaim(true);
        expectedClaimValues = true;

        expectedPrincipal      = principal_;
        expectedInterest       = interest_;
        expectedPaymentDueDate = paymentDueDate_;
    }

}

contract MockRevertingERC20 is MockERC20 {

    constructor(string memory name_, string memory symbol_, uint8 decimals_) MockERC20(name_, symbol_, decimals_) {}

    function transfer(address, uint256) public override pure returns (bool success_) {
        success_;
        require(false);
    }

    function transferFrom(address, address, uint256) public override pure returns (bool success_) {
        success_;
        require(false);
    }

}
