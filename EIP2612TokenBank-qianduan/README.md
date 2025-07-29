# TokenBank - Permit2 存款前端

这是一个基于Next.js的TokenBank前端应用，支持使用Permit2进行无gas授权的存款操作。

## 功能特性

- 🔗 **钱包连接**: 支持MetaMask等钱包连接
- 💰 **余额显示**: 实时显示Token和TokenBank余额
- 📥 **标准存款**: 传统的授权+存款流程
- ⚡ **Permit2存款**: 使用Permit2签名进行无gas授权的存款
- 📤 **提现功能**: 将TokenBank份额兑换回Token
- 🎨 **美观界面**: 使用Ant Design和Tailwind CSS构建的现代化界面

## 技术栈

- **框架**: Next.js 15.4.2
- **语言**: TypeScript
- **样式**: Tailwind CSS + Ant Design
- **区块链**: Wagmi + Viem + Ethers.js
- **状态管理**: React Query

## 合约地址

- **Token**: `0x7f857f3b32b284370d56dcbd61e2563e650a649a`
- **TokenBank**: `0x84133840149C3dd3B4E092ADF29f76352f6f6A59`
- **Permit2**: `0x000000000022D473030F116dDEE9F6B43aC78BA3`

## 安装和运行

1. 安装依赖:
```bash
npm install
# 或
yarn install
# 或
pnpm install
```

2. 启动开发服务器:
```bash
npm run dev
# 或
yarn dev
# 或
pnpm dev
```

3. 打开浏览器访问 [http://localhost:3000](http://localhost:3000)

## 使用说明

1. **连接钱包**: 点击"连接钱包"按钮连接MetaMask
2. **查看余额**: 连接后会自动显示Token和TokenBank余额
3. **标准存款**: 
   - 输入存款金额
   - 点击"标准存款"
   - 需要先授权Token，然后执行存款
4. **Permit2存款**:
   - 输入存款金额
   - 点击"Permit2存款"
   - 使用签名进行无gas授权的存款
5. **提现**: 
   - 输入提现金额
   - 点击"提现"
   - 将TokenBank份额兑换回Token

## 项目结构

```
src/
├── abi/                    # 合约ABI定义
│   ├── EIP2612TokenBank.ts
│   ├── EIP2612Token.ts
│   ├── Permit2.ts
│   └── index.ts
├── config/                 # 配置文件
│   ├── contracts.ts        # 合约地址配置
│   └── wagmi.ts           # Wagmi配置
├── utils/                  # 工具函数
│   └── ethers.ts          # Ethers.js工具函数
└── app/                    # Next.js应用
    ├── layout.tsx         # 根布局
    ├── page.tsx           # 主页面
    ├── providers.tsx      # 提供者组件
    └── globals.css        # 全局样式
```

## 开发说明

### Permit2签名流程

1. 生成随机nonce和deadline
2. 创建Permit2签名数据
3. 用户签名
4. 调用TokenBank的`depositWithPermit2`方法

### 合约交互

- 使用Ethers.js进行合约交互
- 支持标准ERC4626存款和Permit2存款
- 实时余额更新

## 注意事项

- 确保钱包连接到Sepolia测试网
- 确保有足够的Token余额进行存款
- Permit2存款需要用户签名，请确保钱包可用
- 所有操作都在Sepolia测试网上进行

## 许可证

MIT License 