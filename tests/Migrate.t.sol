// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { MapleLoanHarness }          from "./utils/Harnesses.sol";
import { MockFactory, MockMigrator } from "./utils/Mocks.sol";

contract MigrateTests is Test {

    MapleLoanHarness loan    = new MapleLoanHarness();
    MockFactory      factory = new MockFactory();

    function setUp() external {
        loan.__setFactory(address(factory));
    }

    function test_migrate_notFactory() external {
        vm.expectRevert("ML:M:NOT_FACTORY");
        loan.migrate(address(0), new bytes(0));
    }

    function test_migrate_success() external {
        address migrator = address(new MockMigrator());

        vm.prank(address(factory));
        loan.migrate(migrator, new bytes(0));
    }

}
