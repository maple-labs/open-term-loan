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

// TODO: Eventually propose this to `forge-std`.
contract Spied is Test {

    bool internal assertCalls;
    bool internal captureCall;

    uint256 callCount;

    bytes[] internal calls;

    modifier spied() {
        if (captureCall) {
            calls.push(msg.data);
            captureCall = false;
        } else {
            if (assertCalls) {
                assertEq(msg.data, calls[callCount++], "Unexpected call spied");
            }

            _;
        }
    }

    function __expectCall() public {
        assertCalls = true;
        captureCall = true;
    }

}

contract MockLender is Spied {

    function claim(uint256 principal_, uint256 interest_, uint40 paymentDueDate_) external spied {}

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
