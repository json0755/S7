// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {Permit2} from "../src/Permit2.sol";

contract DeployPermit2Script is Script {
    function run() external {
        console2.log("Starting Permit2 deployment...");
        console2.log("Deployer address:", msg.sender);
        console2.log("Current chain ID:", block.chainid);

        vm.startBroadcast();

        // 部署Permit2合约
        Permit2 permit2 = new Permit2();
        
        vm.stopBroadcast();

        console2.log("Permit2 deployed successfully!");
        console2.log("Permit2 address:", address(permit2));
        console2.log("Contract name:", permit2.name());
        console2.log("Contract version:", permit2.version());
        console2.log("Domain Separator:", vm.toString(permit2.DOMAIN_SEPARATOR()));
        
        // Save deployment info to file
        string memory deploymentInfo = string(abi.encodePacked(
            "Permit2 Deployment Info\n",
            "==================\n",
            "Contract address: ", vm.toString(address(permit2)), "\n",
            "Deployer: ", vm.toString(msg.sender), "\n",
            "Chain ID: ", vm.toString(block.chainid), "\n",
            "Block number: ", vm.toString(block.number), "\n",
            "Domain Separator: ", vm.toString(permit2.DOMAIN_SEPARATOR()), "\n"
        ));
        
        // vm.writeFile("./permit2-deployment.txt", deploymentInfo);
        console2.log("Deployment info saved to: permit2-deployment.txt");
    }
} 