// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/TokenBank.sol";
import "../src/MyToken.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        // 1. 先部署 BaseERC20
        // MyToken myToken = new MyToken("BapeToken", "BAPE");
        // console2.log("BaseERC20 address:", address(myToken));
        address myTokenAddress = 0x4e7C8e2c43aC1d69811D2d00d5AD385dB43899fa;
        // 2. 再部署 TokenBank，传入 token 地址
        TokenBank tokenBank = new TokenBank(myTokenAddress);
        console2.log("TokenBank address:", address(tokenBank));
        vm.stopBroadcast();
    }
}