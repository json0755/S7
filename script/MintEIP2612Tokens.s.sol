// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {EIP2612Token} from "../src/07-25/EIP2612Token.sol";

contract MintEIP2612TokensScript is Script {
    // Set your EIP2612Token contract address here
    address constant TOKEN_ADDRESS = 0x0000000000000000000000000000000000000000; // Replace with actual address
    
    // Test user addresses to mint tokens for
    address[] public testUsers = [
        0x1Be31A94361a391bBaFB2a4CCd704F57dc04d4bb, // Replace with your test address
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8  // Replace with another test address
    ];
    
    function run() external {
        require(TOKEN_ADDRESS != address(0), "Please set TOKEN_ADDRESS first");
        
        console2.log("Starting to mint EIP2612Token for test users...");
        console2.log("Token contract address:", TOKEN_ADDRESS);
        console2.log("==========================================");

        vm.startBroadcast();

        EIP2612Token token = EIP2612Token(TOKEN_ADDRESS);
        
        // Verify contract
        console2.log("Token name:", token.name());
        console2.log("Token symbol:", token.symbol());
        console2.log("Current total supply:", token.totalSupply() / 10**token.decimals(), "tokens");
        
        // Mint tokens for each test user
        uint256 mintAmount = 1000; // 1000 tokens
        
        for (uint256 i = 0; i < testUsers.length; i++) {
            address user = testUsers[i];
            uint256 beforeBalance = token.balanceOf(user);
            
            console2.log("Minting tokens for user:", user);
            token.mint(user, mintAmount);
            
            uint256 afterBalance = token.balanceOf(user);
            console2.log("  - Balance before:", beforeBalance / 10**token.decimals(), "tokens");
            console2.log("  - Balance after:", afterBalance / 10**token.decimals(), "tokens");
            console2.log("  - Successfully minted:", mintAmount, "tokens");
            console2.log("");
        }

        vm.stopBroadcast();

        console2.log("==========================================");
        console2.log("Token minting completed!");
        console2.log("New total supply:", token.totalSupply() / 10**token.decimals(), "tokens");
        console2.log("==========================================");
        
        console2.log("Testing suggestions:");
        console2.log("1. Users can now test signature deposit on frontend");
        console2.log("2. Each user has", mintAmount, "test tokens");
        console2.log("3. Can use permitDeposit and depositWithPermit2 functions");
    }
    
    // Helper function: mint tokens for a single user
    function mintForUser(address tokenAddress, address user, uint256 amount) public {
        vm.startBroadcast();
        EIP2612Token token = EIP2612Token(tokenAddress);
        token.mint(user, amount);
        vm.stopBroadcast();
        
        console2.log("Minted", amount, "tokens for user", user);
    }
} 