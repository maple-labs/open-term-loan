// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { MapleLoanHarness }         from "./utils/Harnesses.sol";
import { MockFactory, MockGlobals } from "./utils/Mocks.sol";

contract SetPendingBorrowerTests is Test {

    address currentBorrower = makeAddr("currentBorrower");
    address newBorrower     = makeAddr("newBorrower");

    MockFactory      factoryMock = new MockFactory();
    MapleLoanHarness loan        = new MapleLoanHarness();
    MockGlobals      globals     = new MockGlobals();

    function setUp() external {
        factoryMock.__setGlobals(address(globals));

        loan.__setBorrower(currentBorrower);
        loan.__setFactory(address(factoryMock));
    }

    function test_setPendingBorrower_notBorrower() external {
        vm.expectRevert("ML:SPB:NOT_BORROWER");
        loan.setPendingBorrower(newBorrower);
    }

    function test_setPendingBorrower_invalidBorrower() external {
        vm.prank(currentBorrower);
        vm.expectRevert("ML:SPB:INVALID_BORROWER");
        loan.setPendingBorrower(newBorrower);
    }

    function test_setPendingBorrower_success() external {
        globals.__setIsBorrower(newBorrower, true);

        vm.prank(currentBorrower);
        loan.setPendingBorrower(newBorrower);

        assertEq(loan.pendingBorrower(), newBorrower);
    }

}
