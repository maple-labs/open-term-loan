// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { Utils }            from "./utils/Utils.sol";
import { MapleLoanHarness } from "./utils/Harnesses.sol";
import {
    MockERC20,
    MockFactory,
    MockGlobals,
    MockLender,
    MockRevertingERC20
} from "./utils/Mocks.sol";

contract ProposeNewTermsTests is Test, Utils {

    // TODO: Revisit testing events

    address lender     = makeAddr("lender");
    address refinancer = makeAddr("refinancer");

    MockGlobals      globals = new MockGlobals();
    MapleLoanHarness loan    = new MapleLoanHarness();

    function setUp() external {
        MockFactory mockFactory = new MockFactory();
        
        mockFactory.__setGlobals(address(globals));

        loan.__setFactory(address(mockFactory));
        loan.__setLender(lender);

        globals.__setIsInstanceOf("OT_REFINANCER", refinancer, true);
    }

    // TODO: Add pause test suite for all functions.

    function test_proposeNewTerms_notLender() external {
        vm.expectRevert("ML:PNT:NOT_LENDER");
        loan.proposeNewTerms(refinancer, block.timestamp + 1, new bytes[](0));
    }

    function test_proposeNewTerms_invalidDeadlineBoundary() external {
        vm.expectRevert("ML:PNT:INVALID_DEADLINE");
        vm.prank(lender);
        loan.proposeNewTerms(refinancer, block.timestamp - 1, new bytes[](0));

        vm.prank(lender);
        loan.proposeNewTerms(refinancer, block.timestamp, new bytes[](0));
    }

    function test_proposeNewTerms_invalidRefinancer() external {
        globals.__setIsInstanceOf("OT_REFINANCER", refinancer, false);

        vm.prank(lender);
        vm.expectRevert("ML:PNT:INVALID_REFINANCER");
        loan.proposeNewTerms(refinancer, block.timestamp + 1, new bytes[](0));
    }

    function test_proposeNewTerms_success() external {
        vm.prank(lender);
        loan.proposeNewTerms(refinancer, block.timestamp + 1, new bytes[](1));

        assertEq(loan.refinanceCommitment(), keccak256(abi.encode(refinancer, block.timestamp + 1, new bytes[](1))));
    }

}