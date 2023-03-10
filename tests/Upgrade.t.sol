// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { MapleLoanHarness }         from "./utils/Harnesses.sol";
import { MockFactory, MockGlobals } from "./utils/Mocks.sol";

contract UpgradeTests is Test {

    address borrower = makeAddr("borrower");

    MockFactory      factoryMock = new MockFactory();
    MapleLoanHarness loan        = new MapleLoanHarness();
    MockGlobals      globals     = new MockGlobals();

    function setUp() external {
        factoryMock.__setGlobals(address(globals));

        loan.__setBorrower(borrower);
        loan.__setFactory(address(factoryMock));
    }

    function test_upgrade_protocolPaused() external {
        address newImplementation = address(new MapleLoanHarness());

        globals.__setProtocolPaused(true);

        vm.prank(borrower);
        vm.expectRevert("ML:PROTOCOL_PAUSED");
        loan.upgrade(1, abi.encode(newImplementation));
    }

    function test_upgrade_notBorrower() external {
        address newImplementation = address(new MapleLoanHarness());

        vm.expectRevert("ML:U:NOT_BORROWER");
        loan.upgrade(1, abi.encode(newImplementation));
    }

    function test_upgrade_success() external {
        address newImplementation = address(new MapleLoanHarness());

        vm.prank(borrower);
        loan.upgrade(1, abi.encode(newImplementation));

        assertEq(loan.implementation(), newImplementation);
    }

}
