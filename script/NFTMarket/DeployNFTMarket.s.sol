// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../../src/NFTMarket.sol";

contract DeployNFTMarketScript is Script {
    function run() external {
        vm.startBroadcast();
        // TODO: 替换为你实际部署的 Token 合约地址
        address myTokenAddress = 0x9b394Ab433ffe82BEB54082d7839F10459bbbF91;
        NFTMarket market = new NFTMarket(myTokenAddress);
        console2.log("NFTMarket address:", address(market));
        vm.stopBroadcast();
    }
}