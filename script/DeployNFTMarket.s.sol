// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/NFTMarket.sol";
import "../src/MyNFT.sol";

contract DeployNFTMarketScript is Script {
    function run() external {
        vm.startBroadcast();
        //1.部署FNT合约
        MyNFT myNFT = new MyNFT();
        //2.部署NFTMarket合约，需要传入 token 地址和签名者地址
        address tokenAddress = 0x6085f9a012B952B246E037cc568a0D5DCCcd78BD; // 使用实际的 token 地址
        address signerAddress = msg.sender; // 使用部署者作为签名者
        NFTMarket market = new NFTMarket(tokenAddress, signerAddress);
        //3.mint NFT到NFTMarket合约地址
        myNFT.mintNFT(address(market), "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        console2.log("NFTMarket address:", address(market));
        vm.stopBroadcast();
    }
}