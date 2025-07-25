## S7 智能合约项目

这是一个基于 Foundry 框架的智能合约开发项目，包含多个 DeFi 相关的合约实现。

## 项目概览

### 核心合约

#### EIP2612Token (src/07-25/EIP2612Token.sol)
- **功能**: 基于 EIP2612 标准的 ERC20 代币合约
- **特性**:
  - 支持 `permit()` 函数，允许无 gas 费的授权操作
  - 支持代币铸造和销毁功能（仅限所有者）
  - 支持供应量上限控制
  - 支持批量转账功能
  - 基于 OpenZeppelin 安全标准库实现
- **测试**: `test/EIP2612Token.t.sol` - 包含完整的功能测试和模糊测试

### 其他合约
- **Counter**: 基础计数器合约示例
- **MyToken**: 简单的 ERC20 代币实现
- **NFTMarket**: NFT 市场合约
- **TokenBank** (src/TokenBank.sol): 代币银行合约
  - 支持 ERC20 代币的存款和提款功能
  - **新增**: `permitDeposit()` 函数，支持通过 EIP2612 离线签名进行无 gas 费授权存款
  - 测试文件: `test/TokenBank.t.sol`

## Foundry 工具链

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
# 运行所有测试
$ forge test

# 运行特定合约的测试
$ forge test --match-contract EIP2612TokenTest

# 运行测试并显示详细信息
$ forge test -v
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
