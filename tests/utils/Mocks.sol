// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { MockERC20 } from "../../modules/erc20/contracts/test/mocks/MockERC20.sol";

contract MapleGlobalsMock {

    address public governor;
    address public mapleTreasury;
    address public securityAdmin;

    bool public protocolPaused;

    mapping(address => bool) public isBorrower;
    mapping(address => bool) public isCollateralAsset;
    mapping(address => bool) public isPoolAsset;

    mapping(address => uint256) public platformOriginationFeeRate;
    mapping(address => uint256) public platformServiceFeeRate;

    bool internal _isFactory;

    constructor(address governor_) {
        governor   = governor_;
        _isFactory = true;
    }

    function isFactory(bytes32, address) external view returns (bool) {
        return _isFactory;
    }

    function setMapleTreasury(address mapleTreasury_) external {
        mapleTreasury = mapleTreasury_;
    }

    function setSecurityAdmin(address securityAdmin_) external {
        securityAdmin = securityAdmin_;
    }

    function setPlatformOriginationFeeRate(address poolManager_, uint256 feeRate_) external {
        platformOriginationFeeRate[poolManager_] = feeRate_;
    }

    function setPlatformServiceFeeRate(address poolManager_, uint256 feeRate_) external {
        platformServiceFeeRate[poolManager_] = feeRate_;
    }

    function setProtocolPaused(bool paused_) external {
        protocolPaused = paused_;
    }

    function setValidBorrower(address borrower_, bool isValid_) external {
        isBorrower[borrower_] = isValid_;
    }

    function setValidCollateralAsset(address collateralAsset_, bool isValid_) external {
        isCollateralAsset[collateralAsset_] = isValid_;
    }

    function setValidPoolAsset(address poolAsset_, bool isValid_) external {
        isPoolAsset[poolAsset_] = isValid_;
    }

    function __setGovernor(address governor_) external {
        governor = governor_;
    }

    function __setIsFactory(bool isFactory_) external {
        _isFactory = isFactory_;
    }

}

contract MockFactory {

    address public mapleGlobals;

    constructor(address mapleGlobals_) {
        mapleGlobals = mapleGlobals_;
    }

    function setGlobals(address globals_) external {
        mapleGlobals = globals_;
    }

    function upgradeInstance(uint256, bytes calldata arguments_) external {
        address implementation = abi.decode(arguments_, (address));

        ( bool success, ) = msg.sender.call(abi.encodeWithSignature("setImplementation(address)", implementation));

        require(success);
    }

}

contract MockRevertingERC20 is MockERC20 {

    constructor(string memory name_, string memory symbol_, uint8 decimals_) MockERC20(name_, symbol_, decimals_) {}

    function transfer(address, uint256) public override pure returns (bool success_) {
        success_;
        require(false);
    }

}
