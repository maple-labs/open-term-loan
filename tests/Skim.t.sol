// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

import { MapleLoanHarness }                                        from "./utils/Harnesses.sol";
import { MockERC20, MockFactory, MockGlobals, MockRevertingERC20 } from "./utils/Mocks.sol";
import { Utils }                                                   from "./utils/Utils.sol";

contract SkimTests is Test, Utils {

    event Skimmed(address indexed token, uint256 amount, address indexed destination);

    address account  = makeAddr("account");
    address borrower = makeAddr("borrower");

    MapleLoanHarness loan    = new MapleLoanHarness();
    MockGlobals      globals = new MockGlobals();

    function setUp() public {
        loan.__setBorrower(borrower);
        loan.__setFactory(address(new MockFactory(address(globals))));
    }

    function test_skim_protocolPaused() external {
        globals.__setProtocolPaused(true);
        vm.expectRevert("ML:PROTOCOL_PAUSED");
        loan.skim(address(0), account);
    }

    function test_skim_notBorrower() external {
        vm.expectRevert("ML:S:NOT_BORROWER");
        loan.skim(address(0), account);
    }

    function test_skim_noTokenToSkim() external {
        address asset = address(new MockERC20("Asset", "A", 6));

        loan.__setFundsAsset(asset);

        vm.prank(borrower);
        vm.expectRevert("ML:S:NO_TOKEN_TO_SKIM");
        loan.skim(asset, account);
    }

    function test_skim_revertingToken() external {
        address asset = address(new MockRevertingERC20("Asset", "A", 6));

        loan.__setFundsAsset(asset);

        deal(asset, address(loan), 1);

        vm.prank(borrower);
        vm.expectRevert("ML:S:TRANSFER_FAILED");
        loan.skim(asset, account);
    }

    function test_skim_success() external {
        uint256 amount = 100_000e6;
        address asset  = address(new MockERC20("Asset", "A", 6));

        loan.__setFundsAsset(asset);

        deal(asset, address(loan), amount);

        assertEq(MockERC20(asset).balanceOf(account),       0);
        assertEq(MockERC20(asset).balanceOf(address(loan)), amount);

        vm.expectEmit(true, true, true, true);
        emit Skimmed(asset, amount, account);

        vm.prank(borrower);
        uint256 skimmed = loan.skim(asset, account);

        assertEq(skimmed, amount);

        assertEq(MockERC20(asset).balanceOf(account),       amount);
        assertEq(MockERC20(asset).balanceOf(address(loan)), 0);
    }

}
