// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../../src/NFTMarket.sol";

contract DeployNFTMarketScript is Script {
    function run() external {
        vm.startBroadcast();
        // TODO: 替换为你实际部署的 Token 合约地址
        address myTokenAddress = 0xBe8446a91ec13Cd2d506D90E515635891B736b54;
        // TODO: 替换为项目方签名者地址（可以是部署者或指定地址）
        address signerAddress = msg.sender; // 使用部署者作为默认签名者
        NFTMarket market = new NFTMarket(myTokenAddress, signerAddress);
        console2.log("NFTMarket address:", address(market));
        console2.log("Signer address:", signerAddress);
        vm.stopBroadcast();
    }
}