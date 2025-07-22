// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../../src/NFTMarket.sol";

contract DeployNFTMarketScript is Script {
    function run() external {
        vm.startBroadcast();
        // TODO: 替换为你实际部署的 Token 合约地址
        address myNFTAddress = 0xe080d4b62Ba7e920398325845B0E4Bf79421218f;
        NFTMarket market = new NFTMarket(myNFTAddress);
        console2.log("NFTMarket address:", address(market));
        vm.stopBroadcast();
    }
}