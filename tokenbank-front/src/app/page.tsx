"use client";
import { useState, useMemo, useEffect } from "react";
import { useAccount, useConnect, useDisconnect, useBalance } from "wagmi";
import { useReadContract, useWriteContract, useSignTypedData, useWaitForTransactionReceipt } from "wagmi";
import { tokenBankAbi } from "../../abi/TokenBank";
import { eIP2612TokenAbi } from "../../abi/eIPToken";
import { permit2Abi, PERMIT2_ADDRESS, PERMIT2_DOMAIN_NAME, PERMIT2_DOMAIN_VERSION, type SignatureTransferDetails } from "../../abi/Permit2";
import { Button, Input, Card, Typography, Space, message, Divider, Row, Col, Tooltip, Radio, Switch } from "antd";
import { parseUnits, formatUnits } from "viem";

const TOKENBANK_ADDRESS = "0x7c666d53BA337688B25f0883BFc93f2DF8900bBc" as `0x${string}`;
const TOKEN_ADDRESS = "0x7b661cAc90464E6ca990bb95E66f178ce9F0189F" as `0x${string}`;
const TOKEN_SYMBOL = "BAPE";
const TOKEN_DECIMALS = 18;

export default function TokenBankApp() {
  const { address, isConnected } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const { data: ethBalance } = useBalance({ address, chainId: 11155111 });

  // 配置检查和调试信息
  console.log("🔧 前端配置信息:");
  console.log("- TOKEN_ADDRESS:", TOKEN_ADDRESS);
  console.log("- TOKENBANK_ADDRESS:", TOKENBANK_ADDRESS);
  console.log("- 注意：如果使用旧的MyToken地址，签名存款将无法工作！");

  // 查询 Token 余额
  const { data: tokenBalance, refetch: refetchTokenBalance } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: eIP2612TokenAbi,
    functionName: "balanceOf",
    args: [address as `0x${string}`],
  });

  // 查询用户在 TokenBank 的存款
  const { data: bankBalance, refetch: refetchBankBalance } = useReadContract({
    address: TOKENBANK_ADDRESS,
    abi: tokenBankAbi,
    functionName: "balances",
    args: [address as `0x${string}`],
  });

  // 查询用户的nonce（用于EIP-2612签名）
  const { data: nonces } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: eIP2612TokenAbi,
    functionName: "nonces",
    args: [address as `0x${string}`],
  });

  // 查询DOMAIN_SEPARATOR（用于EIP-2612签名）
  const { data: domainSeparator } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: eIP2612TokenAbi,
    functionName: "DOMAIN_SEPARATOR",
  });

  // 查询用户对Permit2的授权额度
  const { data: permit2Allowance, refetch: refetchPermit2Allowance } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: eIP2612TokenAbi,
    functionName: "allowance",
    args: [address as `0x${string}`, PERMIT2_ADDRESS],
  });

  // 查询Permit2 nonce bitmap (用于生成正确的nonce)
  const { data: nonceBitmap } = useReadContract({
    address: PERMIT2_ADDRESS,
    abi: permit2Abi,
    functionName: "nonceBitmap",
    args: [address as `0x${string}`, BigInt(0)], // 查询第0个word
  });

  // 查询TokenBank合约中的permit2地址，验证配置是否正确
  const { data: tokenBankPermit2Address } = useReadContract({
    address: TOKENBANK_ADDRESS,
    abi: tokenBankAbi,
    functionName: "permit2",
  });

  // 查询TokenBank合约中的token地址，验证配置是否正确
  const { data: tokenBankTokenAddress } = useReadContract({
    address: TOKENBANK_ADDRESS,
    abi: tokenBankAbi,
    functionName: "token",
  });

  // 存款相关状态
  const [depositAmount, setDepositAmount] = useState("");
  const [depositMethod, setDepositMethod] = useState<'traditional' | 'permit' | 'permit2'>('traditional');
  const [pendingTxHash, setPendingTxHash] = useState<`0x${string}` | undefined>(undefined);

  // 合约写入操作
  const { writeContract: approve, writeContractAsync, isPending: isApproving } = useWriteContract();
  const { writeContract: deposit, isPending: isDepositing } = useWriteContract();
  const { writeContract: permitDeposit, isPending: isPermitDepositing } = useWriteContract();
  const { 
    writeContract: permit2Deposit, 
    isPending: isPermit2Depositing,
    data: permit2TxHash,
    error: permit2Error
  } = useWriteContract();

  // 监听交易确认状态
  const { 
    isLoading: isTxPending, 
    isSuccess: isTxSuccess, 
    isError: isTxError,
    error: txError,
    data: txReceipt
  } = useWaitForTransactionReceipt({
    hash: pendingTxHash,
  });

  // 取款
  const [withdrawAmount, setWithdrawAmount] = useState("");
  const { writeContract: withdraw, isPending: isWithdrawing } = useWriteContract();

  // 监听交易确认状态的副作用
  useEffect(() => {
    if (isTxSuccess && txReceipt) {
      console.log("🎉 交易确认成功！");
      console.log("📋 交易收据:", txReceipt);
      message.destroy();
      message.success("交易已确认，存款成功！");
      
      // 刷新余额
      setTimeout(async () => {
        await refetchTokenBalance?.();
        await refetchBankBalance?.();
        console.log("✅ 余额已刷新");
      }, 1000);
      
      // 清除pending状态
      setPendingTxHash(undefined);
    }
    
    if (isTxError && txError) {
      console.error("❌ 交易失败:", txError);
      message.destroy();
      
      let errorMsg = "交易失败";
      if (txError.message?.includes("insufficient funds")) {
        errorMsg = "余额不足或gas费不够";
      } else if (txError.message?.includes("reverted")) {
        errorMsg = "交易被回滚，可能是nonce重复或其他合约错误";
      } else if (txError.message) {
        errorMsg += ": " + txError.message;
      }
      
      message.error(errorMsg);
      setPendingTxHash(undefined);
    }
     }, [isTxSuccess, isTxError, txReceipt, txError, refetchTokenBalance, refetchBankBalance]);

  // 监听permit2交易hash变化，开始监听交易状态
  useEffect(() => {
    if (permit2TxHash && !pendingTxHash) {
      console.log("📋 获取到交易hash，开始监听:", permit2TxHash);
      setPendingTxHash(permit2TxHash);
      setDepositAmount(""); // 清空输入框
      message.destroy();
      message.loading("交易已提交，等待区块链确认...", 0);
    }
  }, [permit2TxHash, pendingTxHash]);

  // 监听permit2交易错误
  useEffect(() => {
    if (permit2Error) {
      console.error("❌ Permit2交易提交失败:", permit2Error);
      message.destroy();
      
      let errorMsg = "交易提交失败";
      if (permit2Error.message?.includes("User rejected")) {
        errorMsg = "用户取消了交易";
      } else if (permit2Error.message?.includes("insufficient funds")) {
        errorMsg = "ETH余额不足，无法支付gas费用";
      } else if (permit2Error.message) {
        errorMsg += ": " + permit2Error.message;
      }
      
      message.error(errorMsg);
    }
  }, [permit2Error]);

  // 签名相关
  const { signTypedData, isPending: isSigning } = useSignTypedData();

  // 传统授权并存款
  const handleDeposit = async () => {
    try {
      await approve({
        address: TOKEN_ADDRESS,
        abi: eIP2612TokenAbi,
        functionName: "approve",
        args: [TOKENBANK_ADDRESS, parseUnits(depositAmount, TOKEN_DECIMALS)],
      });
      await deposit({
        address: TOKENBANK_ADDRESS,
        abi: tokenBankAbi,
        functionName: "deposit",
        args: [parseUnits(depositAmount, TOKEN_DECIMALS)],
      });
      message.success("存款成功！");
      refetchTokenBalance?.();
      refetchBankBalance?.();
      setDepositAmount("");
    } catch (error) {
      console.error("存款失败:", error);
      message.error("存款失败");
    }
  };

  // 生成Permit2 nonce（基于bitmap的正确方式）
  const generatePermit2Nonce = () => {
    // Permit2 nonce格式: word * 256 + bit
    // word = 0 (使用第一个bitmap word)
    // bit = 找一个未使用的位
    
    const word = BigInt(0);
    const bitmap = typeof nonceBitmap === "bigint" ? nonceBitmap : BigInt(0);
    
    console.log("🔢 分析nonce bitmap:");
    console.log("- current bitmap:", bitmap.toString());
    console.log("- bitmap binary:", bitmap.toString(2));
    
    // 找到第一个未使用的位 (0-255)
    let bit = -1;
    for (let i = 0; i < 256; i++) {
      const bitMask = BigInt(1) << BigInt(i);
      if ((bitmap & bitMask) === BigInt(0)) {
        bit = i;
        console.log(`✅ 找到未使用的bit位: ${i}`);
        break;
      } else {
        console.log(`❌ bit位 ${i} 已被使用`);
      }
    }
    
    // 如果前几位都被使用，尝试找一个更靠后的位
    if (bit === -1 || bit === 0) {
      // 使用时间戳的最后几位作为bit
      const timestamp = Date.now();
      bit = (timestamp % 256) + 1; // 避免使用0，从1开始
      console.log(`⚠️ 使用时间戳生成bit位: ${bit}`);
      
      // 再次检查这个bit是否被使用
      const bitMask = BigInt(1) << BigInt(bit);
      if ((bitmap & bitMask) !== BigInt(0)) {
        // 如果还是被使用，就递增找下一个
        for (let i = bit + 1; i < 256; i++) {
          const nextBitMask = BigInt(1) << BigInt(i);
          if ((bitmap & nextBitMask) === BigInt(0)) {
            bit = i;
            console.log(`🔄 递增找到可用bit位: ${i}`);
            break;
          }
        }
      }
    }
    
    // 如果实在找不到，使用随机数但避开已知的使用位
    if (bit === -1) {
      bit = Math.floor(Math.random() * 200) + 50; // 使用50-250范围的随机数
      console.log(`🎲 使用随机bit位: ${bit}`);
    }
    
    const nonce = word * BigInt(256) + BigInt(bit);
    console.log("🔢 生成Permit2 nonce:");
    console.log("- word:", word.toString());
    console.log("- bit:", bit.toString());
    console.log("- nonce:", nonce.toString());
    console.log("- bitmap:", bitmap.toString());
    
    return nonce;
  };

  // 验证合约配置
  const validateContractConfig = () => {
    console.log("🔍 验证合约配置:");
    console.log("- 前端配置的TOKEN_ADDRESS:", TOKEN_ADDRESS);
    console.log("- 前端配置的PERMIT2_ADDRESS:", PERMIT2_ADDRESS);
    console.log("- 前端配置的TOKENBANK_ADDRESS:", TOKENBANK_ADDRESS);
    console.log("- TokenBank合约中的token地址:", tokenBankTokenAddress);
    console.log("- TokenBank合约中的permit2地址:", tokenBankPermit2Address);
    
    const issues = [];
    
    // 检查TokenBank合约中的token地址是否匹配
    if (tokenBankTokenAddress && tokenBankTokenAddress.toLowerCase() !== TOKEN_ADDRESS.toLowerCase()) {
      issues.push(`❌ TOKEN地址不匹配: 前端(${TOKEN_ADDRESS}) vs TokenBank(${tokenBankTokenAddress})`);
    } else if (tokenBankTokenAddress) {
      console.log("✅ TOKEN地址匹配");
    }
    
    // 检查TokenBank合约中的permit2地址是否匹配
    if (tokenBankPermit2Address && tokenBankPermit2Address.toLowerCase() !== PERMIT2_ADDRESS.toLowerCase()) {
      issues.push(`❌ PERMIT2地址不匹配: 前端(${PERMIT2_ADDRESS}) vs TokenBank(${tokenBankPermit2Address})`);
    } else if (tokenBankPermit2Address) {
      console.log("✅ PERMIT2地址匹配");
    }
    
    // 检查用户余额
    const userTokenBalance = typeof tokenBalance === "bigint" ? tokenBalance : BigInt(0);
    if (userTokenBalance === BigInt(0)) {
      issues.push("❌ 用户Token余额为0");
    } else {
      console.log("✅ 用户有Token余额:", userTokenBalance.toString());
    }
    
    // 检查Permit2授权
    const permit2Auth = typeof permit2Allowance === "bigint" ? permit2Allowance : BigInt(0);
    if (permit2Auth === BigInt(0)) {
      issues.push("❌ 用户未授权Permit2合约");
    } else {
      console.log("✅ 用户已授权Permit2:", permit2Auth.toString());
    }
    
    // 检查基础合约功能
    if (!domainSeparator) {
      issues.push("❌ 无法获取DOMAIN_SEPARATOR，Token可能不支持EIP-2612");
    } else {
      console.log("✅ Token支持EIP-2612");
    }
    
    if (nonces === undefined) {
      issues.push("❌ 无法获取nonces");
    } else {
      console.log("✅ 可以获取nonces");
    }
    
    if (issues.length > 0) {
      console.error("⚠️ 发现配置问题:");
      issues.forEach(issue => console.error(issue));
      return false;
    }
    
    console.log("✅ 所有配置检查通过");
    return true;
  };

  // 授权Permit2合约
  const approvePermit2 = async () => {
    try {
      console.log("🔐 开始授权Permit2合约...");
      console.log("🔍 授权参数检查:");
      console.log("- 用户地址:", address);
      console.log("- Token地址:", TOKEN_ADDRESS);
      console.log("- Permit2地址:", PERMIT2_ADDRESS);
      console.log("- 用户Token余额:", tokenBalance?.toString());
      console.log("- 当前授权额度:", permit2Allowance?.toString());

      // 检查基本条件
      if (!address) {
        throw new Error("未连接钱包");
      }

      if (!tokenBalance || tokenBalance === BigInt(0)) {
        throw new Error("Token余额为0，无法进行授权");
      }

      // 检查是否已经有足够授权
      const currentAllowance = typeof permit2Allowance === "bigint" ? permit2Allowance : BigInt(0);
      const maxUint256 = BigInt("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
      
      if (currentAllowance >= maxUint256 / BigInt(2)) {
        console.log("✅ 已有足够授权，无需重复授权");
        message.info("已有足够的Permit2授权");
        return;
      }

      console.log("💰 执行approve交易...");
      console.log("- 调用合约:", TOKEN_ADDRESS);
      console.log("- 授权给:", PERMIT2_ADDRESS);
      console.log("- 授权金额:", maxUint256.toString());

      // 直接使用window.ethereum（已验证工作）
      const hash = await window.ethereum.request({
        method: 'eth_sendTransaction',
        params: [{
          from: address,
          to: TOKEN_ADDRESS,
          data: `0x095ea7b3${PERMIT2_ADDRESS.slice(2).toLowerCase().padStart(64, '0')}ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff`
        }]
      });
      
      console.log("📝 授权交易Hash:", hash);

      console.log("✅ approve交易已提交");
      message.success("Permit2授权成功！");
      refetchPermit2Allowance?.();
    } catch (error: any) {
      console.error("❌ Permit2授权失败:", error);
      console.error("❌ 错误类型:", typeof error);
      console.error("❌ 错误详情:", error?.cause || error?.details || error);
      
      let errorMessage = "Permit2授权失败";
      if (error?.message) {
        errorMessage += ": " + error.message;
      }
      if (error?.cause?.reason) {
        errorMessage += " (" + error.cause.reason + ")";
      }
      
      message.error(errorMessage);
      throw error; // 重新抛出错误，让调用方知道失败了
    }
  };

  // 执行实际的Permit2签名和存款操作
  const executePermit2Deposit = async (amount: bigint) => {
    try {
      const nonce = generatePermit2Nonce();
      const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600); // 1小时后过期

      console.log("🔍 开始Permit2签名流程:");
      console.log("- amount:", amount.toString());
      console.log("- nonce:", nonce.toString());
      console.log("- deadline:", deadline.toString());
      console.log("- TOKEN_ADDRESS:", TOKEN_ADDRESS);
      console.log("- PERMIT2_ADDRESS:", PERMIT2_ADDRESS);
      console.log("- TOKENBANK_ADDRESS:", TOKENBANK_ADDRESS);

      // Permit2 EIP-712 域配置
      const domain = {
        name: PERMIT2_DOMAIN_NAME,
        version: PERMIT2_DOMAIN_VERSION,
        chainId: 11155111, // Sepolia
        verifyingContract: PERMIT2_ADDRESS,
      };

      // Permit2 类型定义
      const types = {
        PermitTransferFrom: [
          { name: "permitted", type: "TokenPermissions" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
        TokenPermissions: [
          { name: "token", type: "address" },
          { name: "amount", type: "uint256" },
        ],
      };

      // 构造签名数据
      const permitData = {
        permitted: {
          token: TOKEN_ADDRESS,
          amount: amount,
        },
        nonce: nonce,
        deadline: deadline,
      };

      console.log("📝 Permit2签名数据:");
      console.log("- domain:", domain);
      console.log("- permitData:", permitData);
      console.log("- types:", types);

      // 验证chainId
      console.log("🔍 ChainId验证:");
      console.log("- 前端配置chainId:", domain.chainId);
      
      // 获取当前网络chainId
      let currentChainId;
      try {
        if (window.ethereum) {
          const chainIdHex = await window.ethereum.request({method: 'eth_chainId'});
          currentChainId = parseInt(chainIdHex, 16);
          console.log("- 当前网络chainId:", currentChainId, `(hex: ${chainIdHex})`);
          
          if (currentChainId !== domain.chainId) {
            console.error("❌ ChainId不匹配！");
            console.error("- 预期:", domain.chainId, "(Sepolia)");
            console.error("- 实际:", currentChainId);
            message.error(`网络不匹配！请切换到Sepolia测试网`);
            return;
          } else {
            console.log("✅ ChainId匹配");
          }
        }
      } catch (err) {
        console.error("❌ 无法获取chainId:", err);
      }

      // 生成Permit2签名
      console.log("🖊️ 调用signTypedData生成Permit2签名");
      signTypedData(
        { 
          domain, 
          types, 
          primaryType: "PermitTransferFrom", 
          message: permitData 
        },
        {
          onSuccess: async (signature: `0x${string}`) => {
            console.log("✅ Permit2签名成功:", signature);
            
            // 验证用户的实际授权状态
            console.log("🔍 验证用户实际授权状态...");
            const currentAllowance = typeof permit2Allowance === "bigint" ? permit2Allowance : BigInt(0);
            console.log("- 用户对Permit2的实际授权:", currentAllowance.toString());
            
            if (currentAllowance < amount) {
              console.error("❌ 用户授权不足！");
              message.error("用户对Permit2的授权不足，需要重新授权");
              return;
            }
            
            try {
              // 构造转账详情
              const transferDetails = {
                to: TOKENBANK_ADDRESS,
                requestedAmount: amount,
              } as const;

              console.log("📞 调用depositWithPermit2合约方法...");
              console.log("- transferDetails:", transferDetails);
              console.log("- 调用参数: [amount, nonce, deadline, transferDetails, signature]");
              console.log("- amount:", amount.toString());
              console.log("- nonce:", nonce.toString());
              console.log("- deadline:", deadline.toString());
              console.log("- signature:", signature);
              
              // 验证签名长度
              console.log("🔍 签名验证:");
              console.log("- 签名长度:", signature.length);
              console.log("- 预期长度: 132 (0x + 64 + 64 + 2)");
              if (signature.length !== 132) {
                console.error("❌ 签名长度不正确!");
              }

              // 调用depositWithPermit2
              console.log("📤 提交depositWithPermit2交易...");
              permit2Deposit({
                address: TOKENBANK_ADDRESS,
                abi: tokenBankAbi,
                functionName: "depositWithPermit2",
                args: [amount, nonce, deadline, transferDetails, signature],
              });

              console.log("⏳ 交易已提交，等待MetaMask确认...");
              message.loading("交易已提交，等待确认...", 0);
            } catch (error) {
              console.error("❌ Permit2 deposit 合约调用错误:", error);
              console.error("❌ 错误详情:", (error as any)?.cause || error);
              
              // 提供手动测试信息
              console.log("🔧 手动测试信息 (可在Etherscan上测试):");
              console.log("📋 合约地址:", TOKENBANK_ADDRESS);
              console.log("📋 函数: depositWithPermit2");
              console.log("📋 参数:");
              console.log("  - amount:", amount.toString());
              console.log("  - nonce:", nonce.toString());
              console.log("  - deadline:", deadline.toString());
              console.log("  - transferDetails.to:", TOKENBANK_ADDRESS);
              console.log("  - transferDetails.requestedAmount:", amount.toString());
              console.log("  - signature:", signature);
              console.log("🔗 Etherscan测试链接:");
              console.log(`https://sepolia.etherscan.io/address/${TOKENBANK_ADDRESS}#writeContract`);
              
              message.error("Permit2签名存款失败: " + (error as Error).message);
            }
          },
          onError: (error: Error) => {
            console.error("❌ Permit2签名被用户拒绝或失败:", error);
            message.error("Permit2签名失败: " + error.message);
          },
        }
      );
    } catch (e) {
      console.error("❌ Permit2签名存款错误:", e);
      message.error("Permit2签名存款失败");
    }
  };

  // Permit2签名存款主函数
  const handlePermit2Deposit = async () => {
    console.log("🚀 开始Permit2签名存款流程");
    console.log("- address:", address);
    console.log("- depositAmount:", depositAmount);
    console.log("- permit2Allowance:", permit2Allowance?.toString());

    if (!address) {
      message.error("未连接钱包");
      return;
    }

    if (!depositAmount || Number(depositAmount) <= 0) {
      message.error("请输入有效的存款金额");
      return;
    }

    // 首先验证合约配置
    console.log("🔧 开始合约配置验证...");
    if (!validateContractConfig()) {
      message.error("合约配置有误，请检查控制台日志");
      return;
    }

    // 检查Permit2授权
    const amount = parseUnits(depositAmount, TOKEN_DECIMALS);
    const allowanceAmount = typeof permit2Allowance === "bigint" ? permit2Allowance : BigInt(0);
    
    console.log("🔍 授权检查:");
    console.log("- 需要金额:", amount.toString());
    console.log("- 授权金额:", allowanceAmount.toString());
    console.log("- 授权是否足够:", allowanceAmount >= amount);

    if (allowanceAmount < amount) {
      console.log("⚠️ 授权不足，开始授权流程");
      message.warning("正在授权Permit2合约，请稍候...");
      try {
        await approvePermit2();
        console.log("✅ 授权成功，准备开始存款...");
        message.success("Permit2授权成功！现在开始存款...");
        
        // 等待状态更新后再次检查授权并执行存款
        setTimeout(async () => {
          console.log("🔄 刷新授权状态并执行存款...");
          await refetchPermit2Allowance?.();
          
          // 再次检查授权状态
          const updatedAllowance = await refetchPermit2Allowance?.();
          console.log("🔍 更新后的授权状态:", updatedAllowance);
          
          await executePermit2Deposit(amount);
        }, 3000); // 增加等待时间确保状态更新
      } catch (error: any) {
        console.error("❌ 授权失败:", error);
        console.error("❌ 授权错误详情:", error?.cause || error?.details || error);
        
        // 提供更详细的错误信息
        let errorMsg = "授权失败";
        if (error?.message?.includes("User rejected")) {
          errorMsg = "用户取消了授权交易";
        } else if (error?.message?.includes("insufficient funds")) {
          errorMsg = "ETH余额不足，无法支付gas费用";
        } else if (error?.message?.includes("execution reverted")) {
          errorMsg = "合约调用失败，请检查Token合约地址是否正确";
        } else if (error?.message) {
          errorMsg += ": " + error.message;
        }
        
        message.error(errorMsg);
      }
      return;
    }

    // 如果已经授权，直接执行存款
    console.log("✅ 授权充足，开始执行Permit2存款");
    await executePermit2Deposit(amount);
  };

  // EIP-2612签名存款
  const handlePermitDeposit = async () => {
    console.log("🚀 开始签名存款流程");
    console.log("- address:", address);
    console.log("- nonces:", nonces);
    console.log("- domainSeparator:", domainSeparator);
    console.log("- depositAmount:", depositAmount);

    if (!address) {
      message.error("未连接钱包");
      return;
    }

    if (nonces === undefined || nonces === null) {
      message.error("无法获取nonces信息");
      return;
    }

    if (!domainSeparator) {
      message.error("无法获取DOMAIN_SEPARATOR信息");
      return;
    }

    if (!depositAmount || Number(depositAmount) <= 0) {
      message.error("请输入有效的存款金额");
      return;
    }

    try {
      const amount = parseUnits(depositAmount, TOKEN_DECIMALS);
      const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600); // 1小时后过期

      // 准备签名数据
      const domain = {
        name: "BapeToken",
        version: "1",
        chainId: 11155111, // Sepolia
        verifyingContract: TOKEN_ADDRESS,
      };

      console.log("🔍 签名存款调试信息:");
      console.log("- address:", address);
      console.log("- nonces:", nonces?.toString());
      console.log("- domainSeparator:", domainSeparator);
      console.log("- amount:", amount.toString());
      console.log("- deadline:", deadline.toString());
      console.log("- domain:", domain);

      const types = {
        Permit: [
          { name: "owner", type: "address" },
          { name: "spender", type: "address" },
          { name: "value", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
      };

      const value = {
        owner: address,
        spender: TOKENBANK_ADDRESS,
        value: amount,
        nonce: nonces,
        deadline: deadline,
      };

      console.log("📝 准备签名的数据:");
      console.log("- types:", types);
      console.log("- value:", value);
      console.log("- 即将调用signTypedData...");

      // 生成签名
      console.log("🖊️ 调用signTypedData");
      signTypedData(
        { domain, types, primaryType: "Permit", message: value },
        {
          onSuccess: async (signature: `0x${string}`) => {
                          console.log("✅ 签名成功:", signature);
              try {
                // 解析签名
                const r = signature.slice(0, 66) as `0x${string}`;
                const s = `0x${signature.slice(66, 130)}` as `0x${string}`;
                const v = parseInt(signature.slice(130, 132), 16);

                console.log("🔧 解析签名:");
                console.log("- r:", r);
                console.log("- s:", s); 
                console.log("- v:", v);

                console.log("📞 调用permitDeposit合约方法...");
                // 调用permitDeposit
                await permitDeposit({
                  address: TOKENBANK_ADDRESS,
                  abi: tokenBankAbi,
                  functionName: "permitDeposit",
                  args: [amount, deadline, v, r, s],
                });

                console.log("🎉 permitDeposit调用成功!");
                message.success("签名存款成功！");
                refetchTokenBalance?.();
                refetchBankBalance?.();
                setDepositAmount("");
              } catch (error) {
                console.error("❌ Permit deposit 合约调用错误:", error);
                message.error("签名存款失败: " + (error as Error).message);
              }
            },
            onError: (error: Error) => {
              console.error("❌ 签名被用户拒绝或失败:", error);
              message.error("签名失败: " + error.message);
            },
        }
      );
    } catch (e) {
      console.error("Error:", e);
      message.error("签名存款失败");
    }
  };

  // 取款
  const handleWithdraw = async () => {
    try {
      await withdraw({
        address: TOKENBANK_ADDRESS,
        abi: tokenBankAbi,
        functionName: "withdraw",
        args: [parseUnits(withdrawAmount, TOKEN_DECIMALS)],
      });
      message.success("取款成功！");
      refetchTokenBalance?.();
      refetchBankBalance?.();
      setWithdrawAmount("");
    } catch (error) {
      console.error("取款失败:", error);
      message.error("取款失败");
    }
  };

  // 按钮点击包装函数
  const handleDepositClick = () => {
    console.log("🖱️ 存款按钮被点击");
    console.log("- depositMethod:", depositMethod);
    console.log("- depositAmount:", depositAmount);
    switch (depositMethod) {
      case 'permit':
        console.log("📝 执行EIP-2612签名存款");
        handlePermitDeposit();
        break;
      case 'permit2':
        console.log("🔐 执行Permit2签名存款");
        handlePermit2Deposit();
        break;
      default:
        console.log("💰 执行传统存款");
        handleDeposit();
        break;
    }
  };

  // 格式化余额
  const walletToken = useMemo(() => typeof tokenBalance === "bigint" ? formatUnits(tokenBalance, TOKEN_DECIMALS) : "0", [tokenBalance]);
  const bankToken = useMemo(() => typeof bankBalance === "bigint" ? formatUnits(bankBalance, TOKEN_DECIMALS) : "0", [bankBalance]);
  const eth = useMemo(() => ethBalance ? Number(formatUnits(ethBalance.value, 18)).toFixed(3) : "-", [ethBalance]);

  return (
    <div style={{ minHeight: "100vh", background: "#f5f6f8" }}>
      <div style={{ maxWidth: 480, margin: "0 auto", paddingTop: 32 }}>
        <Typography.Title level={2} style={{ textAlign: "center", marginBottom: 16 }}>TokenBank DApp</Typography.Title>
        <div style={{ display: "flex", justifyContent: "center", gap: 16, marginBottom: 16 }}>
          <Button type="default" shape="round" size="small" disabled>Sepolia</Button>
          <Button type="default" shape="round" size="small" disabled>
            {eth} ETH
          </Button>
          <Button type="default" shape="round" size="small" disabled>
            {address ? `${address.slice(0, 6)}...${address.slice(-4)}` : "未连接"}
          </Button>
        </div>
        <Card style={{ borderRadius: 16, boxShadow: "0 2px 8px #eee" }}>
          <div style={{ textAlign: "center", marginBottom: 8 }}>
            <Typography.Title level={4} style={{ margin: 0 }}>TokenBank</Typography.Title>
            <Typography.Text type="secondary" style={{ fontSize: 13 }}>网络: Sepolia</Typography.Text>
          </div>
          
          {/* 配置状态提示 */}
          <div style={{ 
            background: "#fff7e6", 
            border: "1px solid #ffd591", 
            borderRadius: 6, 
            padding: 12, 
            marginBottom: 16,
            fontSize: 13
          }}>
            <div style={{ fontWeight: 600, color: "#d4690e", marginBottom: 4 }}>🔧 合约配置</div>
            <div style={{ color: "#8c5e07" }}>
              TOKEN: {TOKEN_ADDRESS.slice(0, 8)}...{TOKEN_ADDRESS.slice(-6)}
              <br />
              TOKENBANK: {TOKENBANK_ADDRESS.slice(0, 8)}...{TOKENBANK_ADDRESS.slice(-6)}
              <br />
              PERMIT2: {PERMIT2_ADDRESS.slice(0, 8)}...{PERMIT2_ADDRESS.slice(-6)}
              <br />
              余额: {walletToken} {TOKEN_SYMBOL} | 授权: {typeof permit2Allowance === "bigint" && permit2Allowance > 0 ? "✅" : "❌"}
              
              {/* 合约地址验证 */}
              <br />
              Token匹配: {tokenBankTokenAddress ? 
                (tokenBankTokenAddress.toLowerCase() === TOKEN_ADDRESS.toLowerCase() ? "✅" : "❌") : "?"} | 
              Permit2匹配: {tokenBankPermit2Address ? 
                (tokenBankPermit2Address.toLowerCase() === PERMIT2_ADDRESS.toLowerCase() ? "✅" : "❌") : "?"}
              
              {depositMethod === 'permit2' && (
                <>
                  <br />
                  DOMAIN_SEPARATOR: {domainSeparator ? "✅" : "❌"} | 
                  Nonces: {nonces !== undefined ? "✅" : "❌"} | 
                  Bitmap: {nonceBitmap !== undefined ? nonceBitmap.toString() : "未加载"}
                  
                  {/* 显示TokenBank合约中的实际地址 */}
                  {(tokenBankTokenAddress || tokenBankPermit2Address) && (
                    <>
                      <br />
                      <small style={{ color: "#666" }}>
                        TokenBank实际配置:<br />
                        Token: {tokenBankTokenAddress ? `${tokenBankTokenAddress.slice(0, 8)}...${tokenBankTokenAddress.slice(-6)}` : "未获取"}<br />
                        Permit2: {tokenBankPermit2Address ? `${tokenBankPermit2Address.slice(0, 8)}...${tokenBankPermit2Address.slice(-6)}` : "未获取"}
                      </small>
                    </>
                  )}
                </>
              )}
            </div>
          </div>
          <Row gutter={16} style={{ marginBottom: 16 }}>
            <Col span={12}>
              <div style={{ background: "#e6f0fa", borderRadius: 8, padding: 16, textAlign: "center" }}>
                <div style={{ color: "#888", fontSize: 14 }}>钱包余额</div>
                <div style={{ fontWeight: 700, fontSize: 28 }}>{walletToken} {TOKEN_SYMBOL}</div>
              </div>
            </Col>
            <Col span={12}>
              <div style={{ background: "#eafae6", borderRadius: 8, padding: 16, textAlign: "center" }}>
                <div style={{ color: "#888", fontSize: 14 }}>银行存款</div>
                <div style={{ fontWeight: 700, fontSize: 28 }}>{bankToken} {TOKEN_SYMBOL}</div>
              </div>
            </Col>
          </Row>
          {!isConnected ? (
            <Button type="primary" block onClick={() => connect({ connector: connectors[0] })} style={{ marginBottom: 8 }}>连接钱包</Button>
          ) : (
            <Button block onClick={() => disconnect()} style={{ marginBottom: 8 }}>断开连接</Button>
          )}
          <Divider style={{ margin: "16px 0" }} />
          <div style={{ marginBottom: 12 }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 8 }}>
              <div style={{ fontWeight: 500 }}>存款到TokenBank</div>
              <Radio.Group 
                size="small"
                value={depositMethod}
                onChange={(e) => setDepositMethod(e.target.value)}
                disabled={!isConnected}
              >
                <Radio.Button value="traditional">传统存款</Radio.Button>
                <Radio.Button value="permit">EIP-2612</Radio.Button>
                <Radio.Button value="permit2">Permit2</Radio.Button>
              </Radio.Group>
            </div>
            <Space.Compact style={{ width: "100%" }}>
              <Input
                type="number"
                min={0}
                value={depositAmount}
                onChange={e => setDepositAmount(e.target.value)}
                placeholder="输入存款金额"
                disabled={!isConnected}
              />
              <Button
                type="primary"
                onClick={handleDepositClick}
                loading={
                  depositMethod === 'permit' ? (isSigning || isPermitDepositing) :
                  depositMethod === 'permit2' ? (isSigning || isPermit2Depositing || isTxPending) :
                  (isApproving || isDepositing)
                }
                disabled={!isConnected || !depositAmount || Number(depositAmount) <= 0 || isTxPending}
              >
                {isTxPending ? "等待确认..." :
                 depositMethod === 'traditional' ? "存款" : 
                 depositMethod === 'permit' ? "EIP-2612签名存款" : 
                 "Permit2签名存款"}
              </Button>
            </Space.Compact>
            {depositMethod !== 'traditional' && (
              <Typography.Text type="secondary" style={{ fontSize: 11, display: "block", marginTop: 4 }}>
                💡 {depositMethod === 'permit' ? 'EIP-2612签名存款无需预先授权，节省一次交易的gas费用' : 
                      'Permit2提供更强大的签名授权机制，支持批量操作和更灵活的权限控制'}
              </Typography.Text>
            )}
            {depositMethod === 'permit2' && (
              <div style={{ fontSize: 11, marginTop: 4 }}>
                <Typography.Text type="secondary">
                  Permit2授权状态: 
                </Typography.Text>
                <Typography.Text 
                  style={{ 
                    color: (typeof permit2Allowance === "bigint" && permit2Allowance > 0) ? "#52c41a" : "#ff4d4f",
                    marginLeft: 4
                  }}
                >
                  {(typeof permit2Allowance === "bigint" && permit2Allowance > 0) ? "✅ 已授权" : "❌ 未授权"}
                </Typography.Text>
                {!(typeof permit2Allowance === "bigint" && permit2Allowance > 0) && (
                  <Typography.Text type="secondary" style={{ display: "block", marginTop: 2 }}>
                    首次使用Permit2需要先授权，后续存款只需签名即可
                  </Typography.Text>
                )}
              </div>
                         )}
             
             {/* 交易状态显示 */}
             {(pendingTxHash || isTxPending) && (
               <div style={{ 
                 background: "#f0f8ff", 
                 border: "1px solid #91d5ff", 
                 borderRadius: 6, 
                 padding: 8, 
                 marginTop: 8, 
                 fontSize: 12
               }}>
                 <div style={{ color: "#1890ff", fontWeight: 600 }}>
                   ⏳ 交易处理中...
                 </div>
                 {pendingTxHash && (
                   <div style={{ color: "#666", marginTop: 4 }}>
                     Hash: <span style={{ fontFamily: "monospace" }}>
                       {pendingTxHash.slice(0, 10)}...{pendingTxHash.slice(-8)}
                     </span>
                     <br />
                     状态: {isTxPending ? "等待确认" : "已提交"}
                   </div>
                 )}
               </div>
             )}
          </div>
          <div style={{ marginBottom: 12 }}>
            <div style={{ fontWeight: 500, marginBottom: 4 }}>从TokenBank取款</div>
            <Space.Compact style={{ width: "100%" }}>
              <Input
                type="number"
                min={0}
                value={withdrawAmount}
                onChange={e => setWithdrawAmount(e.target.value)}
                placeholder="输入取款金额"
                disabled={!isConnected}
              />
              <Button
                type="primary"
                onClick={handleWithdraw}
                loading={isWithdrawing}
                disabled={!isConnected || !withdrawAmount || Number(withdrawAmount) <= 0}
              >取款</Button>
            </Space.Compact>
          </div>
          <Divider style={{ margin: "16px 0" }} />
          <div style={{ color: "#888", fontSize: 13 }}>
            <span>合约地址：</span>
            <Tooltip title={TOKENBANK_ADDRESS}><span style={{ fontFamily: "monospace" }}>{TOKENBANK_ADDRESS.slice(0, 8)}...{TOKENBANK_ADDRESS.slice(-6)}</span></Tooltip>
          </div>
        </Card>
      </div>
    </div>
  );
} 