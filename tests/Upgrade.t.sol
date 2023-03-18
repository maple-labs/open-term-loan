// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { MapleLoanHarness }         from "./utils/Harnesses.sol";
import { MockFactory, MockGlobals } from "./utils/Mocks.sol";

contract UpgradeTests is Test {

    event Upgraded(uint256 toVersion_, bytes arguments_);

    address borrower = makeAddr("borrower");

    MapleLoanHarness loan    = new MapleLoanHarness();
    MockFactory      factory = new MockFactory();
    MockGlobals      globals = new MockGlobals();

    function setUp() external {
        factory.__setGlobals(address(globals));

        loan.__setBorrower(borrower);
        loan.__setFactory(address(factory));
    }

    function test_upgrade_protocolPaused() external {
        globals.__setProtocolPaused(true);

        vm.prank(borrower);
        vm.expectRevert("ML:PROTOCOL_PAUSED");
        loan.upgrade(1, "");
    }

    function test_upgrade_notBorrower() external {
        vm.expectRevert("ML:U:NOT_BORROWER");
        loan.upgrade(1, "");
    }

    function test_upgrade_success() external {
        factory.__expectCall();
        factory.upgradeInstance(1, "");

        vm.expectEmit();
        emit Upgraded(1, "");

        vm.prank(borrower);
        loan.upgrade(1, "");
    }

}
