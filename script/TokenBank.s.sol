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
        address myTokenAddress = 0x05a1ecCcaF01F6898863696832Fdfef90077D1BC;
        // 你的Permit2合约地址（Sepolia部署）
        address permit2Address = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
        // 2. 再部署 TokenBank，传入 token 地址和 permit2 地址
        TokenBank tokenBank = new TokenBank(myTokenAddress, permit2Address);
        console2.log("TokenBank address:", address(tokenBank));
        console2.log("Token address:", myTokenAddress);
        console2.log("Permit2 address:", permit2Address);
        vm.stopBroadcast();
    }
}