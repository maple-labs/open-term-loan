// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { MockERC20 } from "../modules/erc20/contracts/test/mocks/MockERC20.sol";

import { MapleLoanHarness } from "./utils/Harnesses.sol";
import { TestBase }         from "./utils/TestBase.sol";

contract DrawdownTests is TestBase {

    address borrower;
    address lender;

    MapleLoanHarness loan;
    MockERC20        asset;

    function setUp() public override {
        super.setUp();

        borrower = makeAddr("borrower");
        lender   = makeAddr("lender");

        asset = new MockERC20("Asset", "A", 6);
        loan  = MapleLoanHarness(createLoan({
            borrower:    borrower,
            lender:      lender,
            fundsAsset:  address(asset),
            principal:   100_000e6,
            termDetails: [uint32(5 days), uint32(5 days), uint32(30 days)],
            rates:       [uint256(0.1e18), uint256(0), uint256(0)]
        }));
    }

    // TODO: Pause test

    function test_drawdown_notBorrower() external {
        vm.expectRevert("ML:D:NOT_BORROWER");
        loan.drawdown(1, borrower);
    }

    function test_drawdown_transferFail() external {
        vm.prank(borrower);
        vm.expectRevert("ML:D:TRANSFER_FAILED");
        loan.drawdown(1, borrower);
    }

    function test_drawdown_success() external {
        deal(address(asset), address(loan), 100_000e6, true);

        assertEq(asset.balanceOf(address(borrower)), 0);
        assertEq(asset.balanceOf(address(loan)),     100_000e6);

        vm.prank(borrower);
        loan.drawdown(75_000e6, borrower);

        assertEq(asset.balanceOf(address(borrower)), 75_000e6);
        assertEq(asset.balanceOf(address(loan)),     25_000e6);
    }

    function testFuzz_drawdown() external {
        // TODO
    }

}
