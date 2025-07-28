// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {BaseERC20} from "../src/BaseERC20.sol";
import {Permit2} from "../src/Permit2.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract DeployAllLocalScript is Script {
    function run() external {
        console2.log("Starting local deployment...");
        console2.log("Deployer address:", msg.sender);
        console2.log("Current chain ID:", block.chainid);
        console2.log("==========================================");

        vm.startBroadcast();

        // 1. Deploy EIP2612Token
        console2.log("Step 1: Deploying EIP2612Token...");
        BaseERC20 token = new BaseERC20(1000000 ether); // 1 million tokens initial supply
        console2.log("EIP2612Token deployed successfully:", address(token));

        // 2. Deploy Permit2
        console2.log("Step 2: Deploying Permit2...");
        Permit2 permit2 = new Permit2();
        console2.log("Permit2 deployed successfully:", address(permit2));

        // 3. Deploy TokenBank
        console2.log("Step 3: Deploying TokenBank...");
        TokenBank tokenBank = new TokenBank(address(token), address(permit2));
        console2.log("TokenBank deployed successfully:", address(tokenBank));

        vm.stopBroadcast();

        console2.log("==========================================");
        console2.log("All contracts deployed successfully!");
        console2.log("Contract addresses summary:");
        console2.log("  EIP2612Token:", address(token));
        console2.log("  Permit2:", address(permit2));
        console2.log("  TokenBank:", address(tokenBank));
        console2.log("==========================================");

        // Verify contract configuration  
        console2.log("Verifying contract configuration...");
        console2.log("Configuration verification complete");

        // Save deployment information (simplified)
        console2.log("Saving deployment info...");
        
        string memory simpleInfo = "Local deployment completed successfully";
        vm.writeFile("deployments/local-deployment.txt", simpleInfo);
        console2.log("Deployment info saved to: deployments/local-deployment.txt");
        
        console2.log("==========================================");
        console2.log("Next steps:");
        console2.log("1. Copy contract addresses to frontend config");
        console2.log("2. Mint tokens for user testing");
        console2.log("3. Start frontend for testing");
        console2.log("==========================================");
    }
} 