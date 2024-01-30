// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SingleHop} from "../src/SingleHop.sol";

contract CounterTest is Test {
    SingleHop public singleHop;

    function setUp() public {
        singleHop = new SingleHop();
    }

}
