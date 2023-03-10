// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { MapleLoanHarness }         from "./utils/Harnesses.sol";
import { MockFactory, MockGlobals } from "./utils/Mocks.sol";

contract AcceptLenderTests is Test {

    address pendingLender  = makeAddr("pendingLender");

    MockFactory      factoryMock = new MockFactory();
    MapleLoanHarness loan        = new MapleLoanHarness();
    MockGlobals      globals     = new MockGlobals();

    function setUp() external {
        factoryMock.__setGlobals(address(globals));

        loan.__setFactory(address(factoryMock));
    }

    function test_acceptLender_protocolPaused() external {
        globals.__setProtocolPaused(true);

        loan.__setPendingLender(pendingLender);

        vm.expectRevert("ML:PROTOCOL_PAUSED");
        loan.acceptLender();
    }

    function test_acceptLender_notPendingLender() external {
        loan.__setPendingLender(pendingLender);

        vm.expectRevert("ML:AL:NOT_PENDING_LENDER");
        loan.acceptLender();
    }

    function test_acceptLender_success() external {
        loan.__setPendingLender(pendingLender);

        vm.prank(pendingLender);
        loan.acceptLender();

        assertEq(loan.lender(),        pendingLender);
        assertEq(loan.pendingLender(), address(0));
    }

}
