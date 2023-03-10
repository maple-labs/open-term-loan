// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { MapleLoanHarness }         from "./utils/Harnesses.sol";
import { MockFactory, MockGlobals } from "./utils/Mocks.sol";

contract EmptyContract {
    fallback() external { }
}

contract SetImplementationTests is Test {

    MockFactory      factoryMock = new MockFactory();
    MapleLoanHarness loan        = new MapleLoanHarness();
    MockGlobals      globals     = new MockGlobals();

    function setUp() external {
        factoryMock.__setGlobals(address(globals));

        loan.__setFactory(address(factoryMock));
    }

    function test_setImplementation_notFactory() external {
        address someContract = address(new EmptyContract());

        vm.expectRevert("ML:SI:NOT_FACTORY");
        loan.setImplementation(someContract);
    }

    function test_setImplementation_success() external {
        address someContract = address(new EmptyContract());

        vm.prank(address(factoryMock));
        loan.setImplementation(someContract);

        assertEq(loan.implementation(), someContract);
    }

}
