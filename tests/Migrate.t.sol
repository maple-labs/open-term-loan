// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { MapleLoanHarness }         from "./utils/Harnesses.sol";
import { MockFactory, MockGlobals } from "./utils/Mocks.sol";

contract EmptyContract {
    fallback() external { }
}

contract MigrateTests is Test {

    MockFactory      factoryMock = new MockFactory();
    MapleLoanHarness loan    = new MapleLoanHarness();
    MockGlobals      globals = new MockGlobals();

    function setUp() external {
        factoryMock.__setGlobals(address(globals));

        loan.__setFactory(address(factoryMock));
    }

    function test_migrate_notFactory() external {
        address mockMigrator = address(new EmptyContract());

        vm.expectRevert("ML:M:NOT_FACTORY");
        loan.migrate(mockMigrator, new bytes(0));
    }

    function test_migrate_success() external {
        address mockMigrator = address(new EmptyContract());

        vm.prank(address(factoryMock));
        loan.migrate(mockMigrator, new bytes(0));
    }

}
