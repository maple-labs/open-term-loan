// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IMapleLoanFactory } from "../../interfaces/IMapleLoanFactory.sol";

contract Governor {

    /************************/
    /*** Direct Functions ***/
    /************************/

    function mapleLoanFactory_registerImplementation(
        address mapleLoanFactory_,
        uint256 version_,
        address implementationAddress_,
        address initializer_
    ) external {
        IMapleLoanFactory(mapleLoanFactory_).registerImplementation(version_, implementationAddress_, initializer_);
    }

    function mapleLoanFactory_enableUpgradePath(address mapleLoanFactory_, uint256 fromVersion_, uint256 toVersion_, address migrator_) external {
        IMapleLoanFactory(mapleLoanFactory_).enableUpgradePath(fromVersion_, toVersion_, migrator_);
    }

    function mapleLoanFactory_disableUpgradePath(address mapleLoanFactory_, uint256 fromVersion_, uint256 toVersion_) external {
        IMapleLoanFactory(mapleLoanFactory_).disableUpgradePath(fromVersion_, toVersion_);
    }


    /*********************/
    /*** Try Functions ***/
    /*********************/

    function try_mapleLoanFactory_registerImplementation(
        address mapleLoanFactory_,
        uint256 version_,
        address implementationAddress_,
        address initializer_
    ) external returns (bool ok_) {
        ( ok_, ) = mapleLoanFactory_.call(
            abi.encodeWithSelector(IMapleLoanFactory.registerImplementation.selector, version_, implementationAddress_, initializer_)
        );
    }

    function try_mapleLoanFactory_enableUpgradePath(
        address mapleLoanFactory_,
        uint256 fromVersion_,
        uint256 toVersion_,
        address migrator_
    ) external returns (bool ok_) {
        ( ok_, ) = mapleLoanFactory_.call(
            abi.encodeWithSelector(IMapleLoanFactory.enableUpgradePath.selector, fromVersion_, toVersion_, migrator_)
        );
    }

    function try_mapleLoanFactory_disableUpgradePath(
        address mapleLoanFactory_,
        uint256 fromVersion_,
        uint256 toVersion_
    ) external returns (bool ok_) {
        ( ok_, ) = mapleLoanFactory_.call(
            abi.encodeWithSelector(IMapleLoanFactory.disableUpgradePath.selector, fromVersion_, toVersion_)
        );
    }
    
}