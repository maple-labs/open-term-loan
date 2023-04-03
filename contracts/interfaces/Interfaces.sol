// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IMapleGlobalsLike {

    function governor() external view returns (address governor_);

    function isBorrower(address account_) external view returns (bool isBorrower_);

    function isFactory(bytes32 factoryId_, address factory_) external view returns (bool isFactory_);

    function isInstanceOf(bytes32 instanceId_, address instance_) external view returns (bool isInstance_);

    function isPoolAsset(address poolAsset_) external view returns (bool isPoolAsset_);

    function platformServiceFeeRate(address poolManager) external view returns (uint256 platformServiceFeeRate_);

    function protocolPaused() external view returns (bool protocolPaused_);

}

interface ILenderLike {

    function claim(
        int256  principal_,
        uint256 interest_,
        uint256 delegateServiceFee_,
        uint256 platformServiceFee_,
        uint40  paymentDueDate_
    ) external;

    function factory() external view returns (address factory_);

    function poolManager() external view returns (address poolManager_);

}

interface IMapleProxyFactoryLike {

    function isInstance(address instance_) external view returns (bool isInstance_);

    function mapleGlobals() external view returns (address mapleGlobals_);

}
