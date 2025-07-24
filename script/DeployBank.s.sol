// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Bank.sol";

contract DeployBankScript is Script {
    function setUp() public {}

    function run() public {
        //
        vm.startBroadcast();
        Bank bank = new Bank();
        console2.log("Bank address:", address(bank));
        vm.stopBroadcast();
    }
} 