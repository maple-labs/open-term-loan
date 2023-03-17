// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { MapleLoanHarness }         from "./utils/Harnesses.sol";
import { MockFactory, MockGlobals } from "./utils/Mocks.sol";
import { Utils }                    from "./utils/Utils.sol";

contract ProposeNewTermsTests is Test, Utils {

    // TODO: Revisit testing events.

    address lender     = makeAddr("lender");
    address refinancer = makeAddr("refinancer");

    MockGlobals      globals = new MockGlobals();
    MapleLoanHarness loan    = new MapleLoanHarness();

    function setUp() external {
        MockFactory mockFactory = new MockFactory();

        mockFactory.__setGlobals(address(globals));

        loan.__setFactory(address(mockFactory));
        loan.__setLender(lender);
    }

    function test_proposeNewTerms_protocolPaused() external {
        globals.__setProtocolPaused(true);

        vm.expectRevert("ML:PROTOCOL_PAUSED");
        loan.proposeNewTerms(refinancer, block.timestamp + 1, new bytes[](0));
    }

    function test_proposeNewTerms_notLender() external {
        vm.expectRevert("ML:PNT:NOT_LENDER");
        loan.proposeNewTerms(refinancer, block.timestamp + 1, new bytes[](0));
    }

    function test_proposeNewTerms_invalidRefinancer() external {
        vm.expectRevert("ML:PNT:INVALID_REFINANCER");
        vm.prank(lender);
        loan.proposeNewTerms(refinancer, block.timestamp + 1, new bytes[](0));
    }

    function test_proposeNewTerms_emptyCalls() external {
        globals.__setIsInstanceOf("OT_REFINANCER", refinancer, true);

        vm.expectRevert("ML:PNT:EMPTY_CALLS");
        vm.prank(lender);
        loan.proposeNewTerms(refinancer, block.timestamp + 1, new bytes[](0));
    }

    function test_proposeNewTerms_deadlineBoundary() external {
        globals.__setIsInstanceOf("OT_REFINANCER", refinancer, true);

        vm.expectRevert("ML:PNT:INVALID_DEADLINE");
        vm.prank(lender);
        loan.proposeNewTerms(refinancer, block.timestamp - 1, new bytes[](1));

        vm.prank(lender);
        loan.proposeNewTerms(refinancer, block.timestamp, new bytes[](1));
    }

    function test_proposeNewTerms_success() external {
        globals.__setIsInstanceOf("OT_REFINANCER", refinancer, true);

        vm.prank(lender);
        loan.proposeNewTerms(refinancer, block.timestamp + 1, new bytes[](1));

        assertEq(loan.refinanceCommitment(), keccak256(abi.encode(refinancer, block.timestamp + 1, new bytes[](1))));
    }

}
