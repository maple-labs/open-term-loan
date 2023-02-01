// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Test } from "../modules/forge-std/src/Test.sol";

contract TestBase is Test {

    uint256 internal start;

    function setUp() public virtual {
        start = block.timestamp;
    }
    
}
