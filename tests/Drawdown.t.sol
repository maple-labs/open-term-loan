// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleLoan } from "../contracts/interfaces/IMapleLoan.sol";

import { IERC20 } from "../modules/erc20/contracts/interfaces/IERC20.sol";

import { MapleLoanHarness } from "./utils/Harnesses.sol";
import { TestBase }         from "./utils/TestBase.sol";

contract DrawdownTests is TestBase {

    address borrower;
    address lender;

    MapleLoanHarness loan;

    function setUp() public override {
        super.setUp();

        borrower = makeAddr("borrower");
        lender   = makeAddr("lender");

        loan  = MapleLoanHarness(createLoan({
            borrower:    borrower,
            lender:      lender,
            fundsAsset:  asset,
            principal:   100_000e6,
            termDetails: [uint32(5 days), uint32(5 days), uint32(30 days)],
            rates:       [uint256(0.1e18), uint256(0), uint256(0)]
        }));
    }

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
        deal(asset, address(loan), 100_000e6, true);

        assertEq(IERC20(asset).balanceOf(borrower),      0);
        assertEq(IERC20(asset).balanceOf(address(loan)), 100_000e6);

        vm.prank(borrower);
        loan.drawdown(75_000e6, borrower);

        assertEq(IERC20(asset).balanceOf(borrower),      75_000e6);
        assertEq(IERC20(asset).balanceOf(address(loan)), 25_000e6);
    }

}
