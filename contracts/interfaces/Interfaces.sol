// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IMapleGlobalsLike {

    function isBorrower(address account_) external view returns (bool isBorrower_);

    function isFactory(bytes32 factoryId_, address factory_) external view returns (bool isValid_);

    function isPoolAsset(address poolAsset_) external view returns (bool isValid_);

    function protocolPaused() external view returns (bool protocolPaused_);

}

interface ILenderLike {

    function claim(uint256 principal_, uint256 interest_, uint40 paymentDueDate_) external;

    function factory() external view returns (address factory_);

}

interface IMapleProxyFactoryLike {

    function isInstance(address instance_) external view returns (bool isInstance_);

    function mapleGlobals() external view returns (address mapleGlobals_);

}
