// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { MapleLoanHarness } from "./utils/Harnesses.sol";

contract SetPendingLenderTests is Test {

    event PendingLenderSet(address indexed pendingLender_);

    address currentLender = makeAddr("currentLender");
    address newLender     = makeAddr("newLender");

    MapleLoanHarness loan = new MapleLoanHarness();

    function test_setPendingLender_notLender() external {
        vm.expectRevert("ML:SPL:NOT_LENDER");
        loan.setPendingLender(newLender);
    }

    function test_setPendingLender_success() external {
        loan.__setLender(currentLender);

        vm.expectEmit();
        emit PendingLenderSet(newLender);

        vm.prank(currentLender);
        loan.setPendingLender(newLender);

        assertEq(loan.pendingLender(), newLender);
    }

}
