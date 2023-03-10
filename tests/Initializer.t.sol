// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test }  from "../modules/forge-std/src/Test.sol";

import { MapleLoanInitializerHarness }          from "./utils/Harnesses.sol";
import { MockFactory, MockGlobals, MockLender } from "./utils/Mocks.sol";

contract InitializerTests is Test {

    address validBorrower;
    address validFundsAsset;
    address validLender;

    uint32 validGracePeriod     = 1;  // Technically, 0 is valid too, but good to have this to make it easier to maintain this test.
    uint32 validNoticePeriod    = 1;
    uint32 validPaymentInterval = 1;

    uint64 validDelegateServiceFeeRate = 1;  // Technically, 0 is valid too, but good to have this to make it easier to maintain this test.
    uint64 validInterestRate           = 1;  // Technically, 0 is valid too, but good to have this to make it easier to maintain this test.
    uint64 validLateFeeRate            = 1;  // Technically, 0 is valid too, but good to have this to make it easier to maintain this test.
    uint64 validLateInterestPremium    = 1;  // Technically, 0 is valid too, but good to have this to make it easier to maintain this test.

    uint256 validPrincipalRequested = 1;

    MapleLoanInitializerHarness initializer;
    MockGlobals                 globals;
    MockLender                  lender;
    MockFactory                 factory;
    MockFactory                 lenderFactory;

    function setUp() external {
        lender = new MockLender();

        globals         = new MockGlobals();
        factory         = new MockFactory();
        initializer     = new MapleLoanInitializerHarness();
        lenderFactory   = new MockFactory();
        validBorrower   = makeAddr("borrower");
        validFundsAsset = makeAddr("fundsAsset");
        validLender     = address(lender);

        factory.__setGlobals(address(globals));

        globals.__setIsBorrower(validBorrower, true);
        globals.__setIsPoolAsset(validFundsAsset, true);
        globals.__setIsFactory("LOAN_MANAGER", address(lenderFactory), true);

        lender.__setFactory(address(lenderFactory));

        lenderFactory.__setGlobals(address(globals));
        lenderFactory.__setIsInstance(validLender, true);
    }

    function test_initialize_invalidPrincipal() external {
        vm.expectRevert("MLI:I:INVALID_PRINCIPAL");
        initializer.__initialize(
            validBorrower,
            validLender,
            validFundsAsset,
            0,
            [validGracePeriod, validNoticePeriod, validPaymentInterval],
            [validDelegateServiceFeeRate, validInterestRate, validLateFeeRate, validLateInterestPremium]
        );
    }

    function test_initialize_invalidNoticePeriod() external {
        vm.expectRevert("MLI:I:INVALID_NOTICE_PERIOD");
        initializer.__initialize(
            validBorrower,
            validLender,
            validFundsAsset,
            validPrincipalRequested,
            [validGracePeriod, 0, validPaymentInterval],
            [validDelegateServiceFeeRate, validInterestRate, validLateFeeRate, validLateInterestPremium]
        );
    }

    function test_initialize_invalidPaymentInterval() external {
        vm.expectRevert("MLI:I:INVALID_PAYMENT_INTERVAL");
        initializer.__initialize(
            validBorrower,
            validLender,
            validFundsAsset,
            validPrincipalRequested,
            [validGracePeriod, validNoticePeriod, 0],
            [validDelegateServiceFeeRate, validInterestRate, validLateFeeRate, validLateInterestPremium]
        );
    }

    function test_initialize_zeroBorrower() external {
        vm.expectRevert("MLI:I:ZERO_BORROWER");
        vm.prank(address(factory));
        initializer.__initialize(
            address(0),
            validLender,
            validFundsAsset,
            validPrincipalRequested,
            [validGracePeriod, validNoticePeriod, validPaymentInterval],
            [validDelegateServiceFeeRate, validInterestRate, validLateFeeRate, validLateInterestPremium]
        );
    }

    function test_initialize_invalidBorrower() external {
        vm.expectRevert("MLI:I:INVALID_BORROWER");
        vm.prank(address(factory));
        initializer.__initialize(
            makeAddr("invalidBorrower"),
            validLender,
            validFundsAsset,
            validPrincipalRequested,
            [validGracePeriod, validNoticePeriod, validPaymentInterval],
            [validDelegateServiceFeeRate, validInterestRate, validLateFeeRate, validLateInterestPremium]
        );
    }

    function test_initialize_invalidFundsAsset() external {
        vm.expectRevert("MLI:I:INVALID_FUNDS_ASSET");
        vm.prank(address(factory));
        initializer.__initialize(
            validBorrower,
            validLender,
            makeAddr("invalidFundsAsset"),
            validPrincipalRequested,
            [validGracePeriod, validNoticePeriod, validPaymentInterval],
            [validDelegateServiceFeeRate, validInterestRate, validLateFeeRate, validLateInterestPremium]
        );
    }

    function test_initialize_zeroLender() external {
        vm.expectRevert("MLI:I:ZERO_LENDER");
        vm.prank(address(factory));
        initializer.__initialize(
            validBorrower,
            address(0),
            validFundsAsset,
            validPrincipalRequested,
            [validGracePeriod, validNoticePeriod, validPaymentInterval],
            [validDelegateServiceFeeRate, validInterestRate, validLateFeeRate, validLateInterestPremium]
        );
    }

    function test_initialize_invalidLenderFactory() external {
        MockLender invalidLender = new MockLender();

        vm.expectRevert("MLI:I:INVALID_FACTORY");
        vm.prank(address(factory));
        initializer.__initialize(
            validBorrower,
            address(invalidLender),
            validFundsAsset,
            validPrincipalRequested,
            [validGracePeriod, validNoticePeriod, validPaymentInterval],
            [validDelegateServiceFeeRate, validInterestRate, validLateFeeRate, validLateInterestPremium]
        );
    }

    function test_initialize_invalidLenderFactoryInstance() external {
        MockLender invalidLender = new MockLender();
        invalidLender.__setFactory(address(lenderFactory));

        vm.expectRevert("MLI:I:INVALID_INSTANCE");
        vm.prank(address(factory));
        initializer.__initialize(
            validBorrower,
            address(invalidLender),
            validFundsAsset,
            validPrincipalRequested,
            [validGracePeriod, validNoticePeriod, validPaymentInterval],
            [validDelegateServiceFeeRate, validInterestRate, validLateFeeRate, validLateInterestPremium]
        );
    }

    function test_initialize_success() external {
        address poolManager                 = makeAddr("poolManager");
        uint256 validPlatformServiceFeeRate = 1;

        lender.__setPoolManager(poolManager);
        globals.__setPlatformServiceFeeRate(poolManager, validPlatformServiceFeeRate);

        vm.prank(address(factory));
        initializer.__initialize(
            validBorrower,
            validLender,
            validFundsAsset,
            validPrincipalRequested,
            [validGracePeriod, validNoticePeriod, validPaymentInterval],
            [validDelegateServiceFeeRate, validInterestRate, validLateFeeRate, validLateInterestPremium]
        );

        assertEq(initializer.borrower(),               validBorrower);
        assertEq(initializer.lender(),                 validLender);
        assertEq(initializer.fundsAsset(),             validFundsAsset);
        assertEq(initializer.principal(),              validPrincipalRequested);
        assertEq(initializer.gracePeriod(),            validGracePeriod);
        assertEq(initializer.noticePeriod(),           validNoticePeriod);
        assertEq(initializer.paymentInterval(),        validPaymentInterval);
        assertEq(initializer.delegateServiceFeeRate(), validDelegateServiceFeeRate);
        assertEq(initializer.interestRate(),           validInterestRate);
        assertEq(initializer.lateFeeRate(),            validLateFeeRate);
        assertEq(initializer.lateInterestPremium(),    validLateInterestPremium);
        assertEq(initializer.platformServiceFeeRate(), validPlatformServiceFeeRate * 1e12);
    }

}
