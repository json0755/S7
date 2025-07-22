// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../../src/MyToken.sol"; // 路径根据你的项目结构调整

contract DeployMyTokenScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MyToken myToken = new MyToken("BapeToken", "BAPE");
        console2.log("MyToken address:", address(myToken));
        vm.stopBroadcast();
    }
}