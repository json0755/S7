// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {BaseERC20} from "../src/BaseERC20.sol";

contract MintTokensScript is Script {
    function run() external {
        // 从环境变量或硬编码获取地址
        address tokenAddress = vm.envOr("TOKEN_ADDRESS", address(0));
        address recipientAddress = vm.envOr("RECIPIENT_ADDRESS", msg.sender);
        uint256 mintAmount = vm.envOr("MINT_AMOUNT", uint256(10000 ether)); // 默认mint 10,000个token

        require(tokenAddress != address(0), "TOKEN_ADDRESS not set");

        console2.log("Starting mint tokens...");
        console2.log("Token address:", tokenAddress);
        console2.log("Recipient address:", recipientAddress);
        console2.log("Mint amount:", mintAmount);

        vm.startBroadcast();

        BaseERC20 token = BaseERC20(tokenAddress);
        
        // Mint tokens到指定地址
        token.mint(recipientAddress, mintAmount);

        vm.stopBroadcast();

        console2.log("Mint successful!");
        console2.log("Balance info:");
        console2.log("  Recipient balance:", token.balanceOf(recipientAddress));
        console2.log("  Total supply:", token.totalSupply());
    }

    // Convenience function: mint with specified parameters
    function mintTo(address tokenAddress, address recipient, uint256 amount) external {
        console2.log("Starting mint tokens...");
        console2.log("Token address:", tokenAddress);
        console2.log("Recipient address:", recipient);
        console2.log("Mint amount:", amount);

        vm.startBroadcast();

        BaseERC20 token = BaseERC20(tokenAddress);
        token.mint(recipient, amount);

        vm.stopBroadcast();

        console2.log("Mint successful!");
        console2.log("New balance:", token.balanceOf(recipient));
    }
} 