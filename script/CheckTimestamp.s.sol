// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

contract CheckTimestamp is Script {
    function run() public view {
        console.log("区块链当前时间戳:", block.timestamp);
        console.log("区块链当前时间 (可读格式):", block.timestamp);
    }
}