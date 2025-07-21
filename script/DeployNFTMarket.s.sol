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
        //2.部署NFTMarket合约，构造参数传NFT合约地址
        NFTMarket market = new NFTMarket(address(myNFT));
        //如果你想让NFTMarket合约拥有NFT(比如用于上架、买卖等场景)，你就应该把NFT mint到NFTMarket合约地址        NFTMarket market = new NFTMarket(address(myNFT));
        //3.mint NFT到NFTMarket合约地址
        myNFT.mintNFT(address(market), "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        console2.log("NFTMarket address:", address(market));
        vm.stopBroadcast();
    }
}