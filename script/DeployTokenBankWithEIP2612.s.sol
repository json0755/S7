// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {EIP2612Token} from "../src/07-25/EIP2612Token.sol";
import {Permit2} from "../src/Permit2.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract DeployTokenBankWithEIP2612Script is Script {
    function run() external {
        console2.log("Starting deployment of Permit2-enabled TokenBank system...");
        console2.log("Deployer address:", msg.sender);
        console2.log("Chain ID:", block.chainid);
        console2.log("==========================================");

        vm.startBroadcast();

        // 1. Deploy EIP2612Token
        console2.log("Step 1: Deploying EIP2612Token...");
        EIP2612Token token = new EIP2612Token(
            "BapeToken",    // name
            "BAPE",        // symbol  
            10000,         // initialSupply (10,000 tokens)
            18,            // decimals
            0              // supplyCap (0 = no cap)
        );
        console2.log("EIP2612Token deployed at:", address(token));

        // 2. Deploy Permit2
        console2.log("Step 2: Deploying Permit2...");
        Permit2 permit2 = new Permit2();
        console2.log("Permit2 deployed at:", address(permit2));

        // 3. Deploy TokenBank
        console2.log("Step 3: Deploying TokenBank...");
        TokenBank tokenBank = new TokenBank(address(token), address(permit2));
        console2.log("TokenBank deployed at:", address(tokenBank));

        vm.stopBroadcast();

        console2.log("==========================================");
        console2.log("All contracts deployed successfully!");
        console2.log("Contract addresses:");
        console2.log("  EIP2612Token (with permit):", address(token));
        console2.log("  Permit2:", address(permit2));
        console2.log("  TokenBank:", address(tokenBank));
        console2.log("==========================================");

        // Verify configuration
        console2.log("Verifying contract configuration...");
        
        require(address(tokenBank.token()) == address(token), "TokenBank token address mismatch");
        require(address(tokenBank.permit2()) == address(permit2), "TokenBank permit2 address mismatch");
        
        // Verify token properties
        console2.log("Token name:", token.name());
        console2.log("Token symbol:", token.symbol());
        console2.log("Token decimals:", token.decimals());
        console2.log("Token total supply:", token.totalSupply() / 10**token.decimals(), "tokens");
        console2.log("Deployer token balance:", token.balanceOf(msg.sender) / 10**token.decimals(), "tokens");
        
        console2.log("Configuration verified successfully!");

        console2.log("==========================================");
        console2.log("Frontend configuration:");
        console2.log("TOKEN_ADDRESS =", address(token));
        console2.log("TOKENBANK_ADDRESS =", address(tokenBank));
        console2.log("PERMIT2_ADDRESS =", address(permit2));
        console2.log("==========================================");
    }
} 