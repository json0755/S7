// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../../src/MyNFT.sol";

contract DeployMyNFTScript is Script {
    function run() external {
        vm.startBroadcast();
        MyNFT myNFT = new MyNFT();
        console2.log("MyNFT address:", address(myNFT));
        vm.stopBroadcast();
    }
}