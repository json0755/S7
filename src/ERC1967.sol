/**
 *Submitted for verification at Etherscan.io on 2025-03-29
*/
// 该文件已于2025-03-29提交到Etherscan进行验证

// Sources flattened with hardhat v2.19.1 https://hardhat.org
// 该文件由 hardhat v2.19.1 工具flatten（扁平化）生成

// SPDX-License-Identifier: MIT
// 版权声明，遵循MIT开源协议

// File @openzeppelin/contracts/interfaces/draft-IERC1822.sol@v4.9.3
// 引入OpenZeppelin的IERC1822接口，版本v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)
// 版权声明，OpenZeppelin合约，最后更新于v4.5.0

pragma solidity ^0.8.0; // 指定Solidity编译器版本为0.8.0及以上

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 * ERC1822：通用可升级代理标准（UUPS），定义了一种通过简化代理实现可升级性的方式，升级完全由当前实现合约控制。
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     * 返回可代理合约假定用于存储实现合约地址的存储槽（slot）。
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     * 重要提示：指向可代理合约的代理本身不应被视为可代理，否则可能导致代理升级到自身后死循环，直到耗尽gas。因此，如果通过代理调用该函数，必须revert。
     */
    function proxiableUUID() external view returns (bytes32); // 返回实现合约地址的存储槽标识
}


// File @openzeppelin/contracts/interfaces/IERC1967.sol@v4.9.3
// 引入OpenZeppelin的IERC1967接口，版本v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)
// 版权声明，OpenZeppelin合约，最后更新于v4.9.0

pragma solidity ^0.8.0; // 指定Solidity编译器版本为0.8.0及以上

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 * ERC-1967：代理存储槽标准。该接口包含ERC标准中定义的事件。
 *
 * _Available since v4.8.3._
 * 自v4.8.3版本起可用。
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     * 当实现合约被升级时触发的事件。
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     * 当管理员账户发生变更时触发的事件。
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     * 当beacon合约发生变更时触发的事件。
     */
    event BeaconUpgraded(address indexed beacon);
}


// File @openzeppelin/contracts/proxy/beacon/IBeacon.sol@v4.9.3
// 引入OpenZeppelin的IBeacon接口，版本v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)
// 版权声明，OpenZeppelin合约，版本v4.4.1

pragma solidity ^0.8.0; // 指定Solidity编译器版本为0.8.0及以上

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 * 这是BeaconProxy代理合约期望的beacon接口。
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     * 必须返回一个可作为delegatecall目标的合约地址。
     *
     * {BeaconProxy} will check that this address is a contract.
     * BeaconProxy会检查该地址是否为合约。
     */
    function implementation() external view returns (address); // 返回实现合约地址
}


// File @openzeppelin/contracts/utils/Address.sol@v4.9.3
// 引入OpenZeppelin的Address工具库，版本v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)
// 版权声明，OpenZeppelin合约，最后更新于v4.9.0

pragma solidity ^0.8.1; // 指定Solidity编译器版本为0.8.1及以上

/**
 * @dev Collection of functions related to the address type
 * 与地址类型相关的函数集合
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     * 如果`account`是合约则返回true。
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     * 假设此函数返回false的地址是外部拥有账户（EOA）而不是合约是不安全的。
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     * 此外，`isContract`对以下类型的地址将返回false：
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     *  - 外部拥有账户
     *  - 正在构造中的合约
     *  - 将要创建合约的地址
     *  - 曾经存在合约但已被销毁的地址
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * 此外，如果同一交易中的目标合约已被安排SELFDESTRUCT（自毁），
     * isContract 也会返回 true，但只有在交易结束时才生效。
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     * 不要依赖 isContract 来防止闪电贷攻击！
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * 阻止合约调用并不推荐，这会破坏可组合性，影响如 Gnosis Safe 这类智能钱包的支持，
     * 并且无法真正提供安全性，因为可以通过合约构造函数绕过。
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.
        // 该方法依赖 extcodesize/address.code.length，
        // 对于正在构造中的合约会返回0，因为代码只有在构造函数结束后才会存储。

        return account.code.length > 0; // 判断该地址的代码长度是否大于0，大于0则为合约
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     * 替代Solidity的`transfer`：将`amount` wei发送给`recipient`，
     * 转发所有可用gas，失败时回退。
     *
     * https://eips.ethereum.org/EIPS/eip1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     * EIP1884提升了某些操作码的gas消耗，可能导致合约超出transfer的2300 gas限制，
     * 使其无法通过transfer接收资金。sendValue消除了这一限制。
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     * 重要：由于控制权转移给了recipient，需注意不要产生重入漏洞。
     * 建议使用ReentrancyGuard或"检查-效果-交互"模式。
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance"); // 检查当前合约余额是否足够

        (bool success, ) = recipient.call{value: amount}(""); // 使用call发送ETH，转发所有gas
        require(success, "Address: unable to send value, recipient may have reverted"); // 检查发送是否成功
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     * 使用低级`call`执行Solidity函数调用。普通的call不安全，建议用本函数替代。
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     * 如果`target`回退（revert），本函数会像普通Solidity函数一样抛出异常。
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     * 返回原始返回数据。要转换为期望的返回值，请用abi.decode。
     *
     * Requirements:
     * 要求：
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * - `target`必须是合约
     * - 用`data`调用`target`不能回退
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        // 调用带value的functionCallWithValue，value为0
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     * 与functionCall相同，但当`target`回退时，使用`errorMessage`作为回退原因。
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        // 调用带value的functionCallWithValue，value为0
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     * 与functionCall相同，但同时向`target`转账`value` wei。
     *
     * Requirements:
     * 要求：
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * - 调用合约余额不少于`value`
     * - 被调用的Solidity函数必须为payable
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        // 调用带错误信息的functionCallWithValue
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     * 与functionCallWithValue相同，但当`target`回退时，使用`errorMessage`作为回退原因。
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call"); // 检查合约余额
        (bool success, bytes memory returndata) = target.call{value: value}(data); // 低级call
        return verifyCallResultFromTarget(target, success, returndata, errorMessage); // 校验call结果
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     * 与functionCall相同，但执行静态调用（staticcall）。
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     * 与functionCall相同，但执行静态调用（staticcall），并自定义错误信息。
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data); // 执行staticcall
        return verifyCallResultFromTarget(target, success, returndata, errorMessage); // 校验结果
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     * 与functionCall相同，但执行委托调用（delegatecall）。
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     * 与functionCall相同，但执行委托调用（delegatecall），并自定义错误信息。
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data); // 执行delegatecall
        return verifyCallResultFromTarget(target, success, returndata, errorMessage); // 校验结果
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     * 工具函数：校验低级调用是否成功，如果失败则回退（抛出错误信息或原始回退原因）。
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target, // 目标合约地址
        bool success, // 调用是否成功
        bytes memory returndata, // 返回的原始数据
        string memory errorMessage // 自定义错误信息
    ) internal view returns (bytes memory) {
        if (success) { // 如果调用成功
            if (returndata.length == 0) { // 如果返回数据为空
                // 仅当调用成功且返回数据为空时，检查目标是否为合约
                // 否则我们已经知道它是一个合约
                require(isContract(target), "Address: call to non-contract"); // 要求目标必须是合约
            }
            return returndata; // 返回原始返回数据
        } else { // 如果调用失败
            _revert(returndata, errorMessage); // 调用内部回退函数
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     * 工具函数：校验低级调用是否成功，如果失败则回退（抛出错误信息或原始回退原因）。
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success, // 调用是否成功
        bytes memory returndata, // 返回的原始数据
        string memory errorMessage // 自定义错误信息
    ) internal pure returns (bytes memory) {
        if (success) { // 如果调用成功
            return returndata; // 返回原始返回数据
        } else { // 如果调用失败
            _revert(returndata, errorMessage); // 调用内部回退函数
        }
    }

    /**
     * @dev 内部回退函数：查找回退原因并在存在时向上抛出
     */
    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // 查找回退原因，如果存在则向上抛出
        if (returndata.length > 0) { // 如果返回数据长度大于0
            // 向上抛出回退原因的最简单方法是使用汇编通过内存操作
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata) // 获取返回数据的大小
                revert(add(32, returndata), returndata_size) // 回退，跳过32字节的长度前缀
            }
        } else { // 如果返回数据为空
            revert(errorMessage); // 使用自定义错误信息回退
        }
    }
}


// File @openzeppelin/contracts/utils/StorageSlot.sol@v4.9.3
// 引入OpenZeppelin的StorageSlot工具库，版本v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// 该文件是从scripts/generate/templates/StorageSlot.js程序化生成的。

pragma solidity ^0.8.0; // 指定Solidity编译器版本为0.8.0及以上

/**
 * @dev 用于读取和写入特定存储槽的原始类型的库。
 *
 * 存储槽通常用于在处理可升级合约时避免存储冲突。
 * 该库帮助读取和写入这些槽，而无需内联汇编。
 *
 * 该库中的函数返回包含可用于读取或写入的`value`成员的Slot结构体。
 *
 * 设置ERC1967实现槽的示例用法：
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * 自v4.1版本起支持`address`、`bool`、`bytes32`、`uint256`。
 * 自v4.9版本起支持`string`、`bytes`。
 */
library StorageSlot {
    // 地址槽结构体，用于存储地址类型
    struct AddressSlot {
        address value; // 存储的地址值
    }

    // 布尔槽结构体，用于存储布尔类型
    struct BooleanSlot {
        bool value; // 存储的布尔值
    }

    // 字节32槽结构体，用于存储bytes32类型
    struct Bytes32Slot {
        bytes32 value; // 存储的bytes32值
    }

    // 无符号整数256槽结构体，用于存储uint256类型
    struct Uint256Slot {
        uint256 value; // 存储的uint256值
    }

    // 字符串槽结构体，用于存储字符串类型
    struct StringSlot {
        string value; // 存储的字符串值
    }

    // 字节槽结构体，用于存储字节类型
    struct BytesSlot {
        bytes value; // 存储的字节值
    }

    /**
     * @dev 返回位于`slot`的`AddressSlot`结构体，其成员`value`指向该槽。
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot // 将传入的槽位置赋给返回结构体的slot属性
        }
    }

    /**
     * @dev 返回位于`slot`的`BooleanSlot`结构体，其成员`value`指向该槽。
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot // 将传入的槽位置赋给返回结构体的slot属性
        }
    }

    /**
     * @dev 返回位于`slot`的`Bytes32Slot`结构体，其成员`value`指向该槽。
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot // 将传入的槽位置赋给返回结构体的slot属性
        }
    }

    /**
     * @dev 返回位于`slot`的`Uint256Slot`结构体，其成员`value`指向该槽。
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot // 将传入的槽位置赋给返回结构体的slot属性
        }
    }

    /**
     * @dev 返回位于`slot`的`StringSlot`结构体，其成员`value`指向该槽。
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot // 将传入的槽位置赋给返回结构体的slot属性
        }
    }

    /**
     * @dev 返回字符串存储指针`store`的`StringSlot`表示。
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot // 将传入字符串的槽位置赋给返回结构体的slot属性
        }
    }

    /**
     * @dev 返回位于`slot`的`BytesSlot`结构体，其成员`value`指向该槽。
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot // 将传入的槽位置赋给返回结构体的slot属性
        }
    }

    /**
     * @dev 返回字节存储指针`store`的`BytesSlot`表示。
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot // 将传入字节数组的槽位置赋给返回结构体的slot属性
        }
    }
}


// File @openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol@v4.9.3
// 引入OpenZeppelin的ERC1967Upgrade抽象合约，版本v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)
// 版权声明，OpenZeppelin合约，最后更新于v4.9.0

pragma solidity ^0.8.2; // 指定Solidity编译器版本为0.8.2及以上

/**
 * @dev 这个抽象合约为 https://eips.ethereum.org/EIPS/eip1967[EIP1967] 槽提供了getter函数和事件发射更新函数。
 *
 * 自v4.1版本起可用。
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // 这是"eip1967.proxy.rollback"的keccak-256哈希值减1
    // 用于存储回滚标志的存储槽
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev 存储当前实现合约地址的存储槽。
     * 这是"eip1967.proxy.implementation"的keccak-256哈希值减1，
     * 并在构造函数中进行验证。
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev 返回当前实现合约地址。
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value; // 从实现槽中读取当前实现合约地址
    }

    /**
     * @dev 在EIP1967实现槽中存储新的地址。
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract"); // 要求新实现必须是合约
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation; // 将新实现地址存储到实现槽中
    }

    /**
     * @dev 执行实现升级
     *
     * 发射{Upgraded}事件。
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation); // 设置新的实现地址
        emit Upgraded(newImplementation); // 发射升级事件
    }

    /**
     * @dev 执行实现升级，并带有额外的设置调用。
     *
     * 发射{Upgraded}事件。
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation); // 先升级到新实现
        if (data.length > 0 || forceCall) { // 如果有数据或强制调用
            Address.functionDelegateCall(newImplementation, data); // 对新实现执行委托调用
        }
    }

    /**
     * @dev 执行实现升级，包含UUPS代理的安全检查，以及额外的设置调用。
     *
     * 发射{Upgraded}事件。
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // 从旧实现升级将执行回滚测试。此测试要求新实现能够升级回旧的、不符合ERC1822的实现。
        // 移除这个特殊情况将破坏从旧UUPS实现到新实现的升级路径。
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) { // 如果回滚槽为true
            _setImplementation(newImplementation); // 直接设置新实现
        } else { // 否则进行UUPS兼容性检查
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) { // 尝试获取新实现的UUID
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID"); // 要求UUID匹配实现槽
            } catch { // 如果调用失败
                revert("ERC1967Upgrade: new implementation is not UUPS"); // 回退：新实现不是UUPS
            }
            _upgradeToAndCall(newImplementation, data, forceCall); // 执行升级和调用
        }
    }

    /**
     * @dev 存储合约管理员的存储槽。
     * 这是"eip1967.proxy.admin"的keccak-256哈希值减1，
     * 并在构造函数中进行验证。
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev 返回当前管理员。
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value; // 从管理员槽中读取当前管理员地址
    }

    /**
     * @dev 在EIP1967管理员槽中存储新地址。
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address"); // 要求新管理员不能为零地址
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin; // 将新管理员地址存储到管理员槽中
    }

    /**
     * @dev 更改代理的管理员。
     *
     * 发射{AdminChanged}事件。
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin); // 发射管理员变更事件
        _setAdmin(newAdmin); // 设置新管理员
    }

    /**
     * @dev 定义此代理实现的UpgradeableBeacon合约的存储槽。
     * 这是bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1))，并在构造函数中进行验证。
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev 返回当前beacon。
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value; // 从beacon槽中读取当前beacon地址
    }

    /**
     * @dev 在EIP1967 beacon槽中存储新的beacon。
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract"); // 要求新beacon必须是合约
        require(
            Address.isContract(IBeacon(newBeacon).implementation()), // 要求beacon的实现必须是合约
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon; // 将新beacon地址存储到beacon槽中
    }

    /**
     * @dev 执行beacon升级，并带有额外的设置调用。注意：这会升级beacon的地址，
     * 但不会升级beacon中包含的实现（参见{UpgradeableBeacon-_setImplementation}）。
     *
     * 发射{BeaconUpgraded}事件。
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon); // 设置新的beacon
        emit BeaconUpgraded(newBeacon); // 发射beacon升级事件
        if (data.length > 0 || forceCall) { // 如果有数据或强制调用
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data); // 对beacon的实现执行委托调用
        }
    }
}


// File @openzeppelin/contracts/proxy/Proxy.sol@v4.9.3
// 引入OpenZeppelin的Proxy抽象合约，版本v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)
// 版权声明，OpenZeppelin合约，最后更新于v4.6.0

pragma solidity ^0.8.0; // 指定Solidity编译器版本为0.8.0及以上

/**
 * @dev 这个抽象合约提供了一个fallback函数，使用EVM指令`delegatecall`将所有调用委托给另一个合约。
 * 我们将第二个合约称为代理后面的_implementation_，它必须通过重写虚拟{_implementation}函数来指定。
 *
 * 此外，可以通过{_fallback}函数手动触发对实现的委托，或通过{_delegate}函数委托给不同的合约。
 *
 * 委托调用的成功和返回数据将返回给代理的调用者。
 */
abstract contract Proxy {
    /**
     * @dev 将当前调用委托给`implementation`。
     *
     * 此函数不会返回到其内部调用站点，它将直接返回到外部调用者。
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // 复制msg.data。我们在这个内联汇编块中完全控制内存，
            // 因为它不会返回到Solidity代码。我们覆盖内存位置0处的Solidity暂存区。
            calldatacopy(0, 0, calldatasize()) // 将调用数据复制到内存位置0

            // 调用实现合约。
            // out和outsize为0，因为我们还不知道大小。
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0) // 执行委托调用

            // 复制返回的数据。
            returndatacopy(0, 0, returndatasize()) // 将返回数据复制到内存位置0

            switch result // 根据结果进行分支
            // delegatecall在错误时返回0。
            case 0 { // 如果调用失败
                revert(0, returndatasize()) // 回退，包含返回数据
            }
            default { // 如果调用成功
                return(0, returndatasize()) // 返回，包含返回数据
            }
        }
    }

    /**
     * @dev 这是一个应该被重写的虚拟函数，以便它返回fallback函数和{_fallback}应该委托的地址。
     */
    function _implementation() internal view virtual returns (address); // 返回实现合约地址

    /**
     * @dev 将当前调用委托给`_implementation()`返回的地址。
     *
     * 此函数不会返回到其内部调用站点，它将直接返回到外部调用者。
     */
    function _fallback() internal virtual {
        _beforeFallback(); // 在fallback之前执行
        _delegate(_implementation()); // 委托给实现合约
    }

    /**
     * @dev Fallback函数，将调用委托给`_implementation()`返回的地址。
     * 如果合约中没有其他函数匹配调用数据，将运行此函数。
     */
    fallback() external payable virtual {
        _fallback(); // 调用内部fallback函数
    }

    /**
     * @dev 当调用数据为空时运行的fallback函数，将调用委托给`_implementation()`返回的地址。
     */
    receive() external payable virtual {
        _fallback(); // 调用内部fallback函数
    }

    /**
     * @dev 在回退到实现之前调用的钩子函数。可能作为手动`_fallback`调用的一部分发生，
     * 或作为Solidity `fallback`或`receive`函数的一部分发生。
     *
     * 如果被重写，应该调用`super._beforeFallback()`。
     */
    function _beforeFallback() internal virtual {} // 空的钩子函数，子合约可以重写
}


// File @openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol@v4.9.3
// 引入OpenZeppelin的ERC1967Proxy合约，版本v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)
// 版权声明，OpenZeppelin合约，最后更新于v4.7.0

pragma solidity ^0.8.0; // 指定Solidity编译器版本为0.8.0及以上

/**
 * @dev 这个合约实现了一个可升级的代理。它是可升级的，因为调用被委托给一个可以更改的实现地址。
 * 这个地址存储在由 https://eips.ethereum.org/EIPS/eip1967[EIP1967] 指定的存储位置中，
 * 这样它就不会与代理后面的实现的存储布局冲突。
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade { // 继承Proxy和ERC1967Upgrade
    /**
     * @dev 使用由`_logic`指定的初始实现初始化可升级代理。
     *
     * 如果`_data`非空，它被用作对`_logic`的委托调用中的数据。这通常是一个编码的函数调用，
     * 允许像Solidity构造函数一样初始化代理的存储。
     */
    constructor(address _logic, bytes memory _data) payable { // 构造函数，接收实现地址和初始化数据
        _upgradeToAndCall(_logic, _data, false); // 升级到指定实现并调用初始化函数
    }

    /**
     * @dev 返回当前实现地址。
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation(); // 从ERC1967Upgrade获取当前实现地址
    }
}


// File contracts/mocks/TransparentUpgradeableProxy.sol
// 引入透明可升级代理合约

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/transparent/TransparentUpgradeableProxy.sol)
// 版权声明，OpenZeppelin合约，最后更新于v4.9.0

pragma solidity ^0.8.0; // 指定Solidity编译器版本为0.8.0及以上

/**
 * @dev {TransparentUpgradeableProxy}的接口。为了实现透明性，{TransparentUpgradeableProxy}
 * 不直接实现此接口，其某些函数通过内部调度机制实现。编译器不知道这些函数是由{TransparentUpgradeableProxy}实现的，
 * 不会将它们包含在ABI中，因此必须使用此接口与之交互。
 */
interface ITransparentUpgradeableProxy is IERC1967 { // 继承IERC1967接口
    function admin() external view returns (address); // 返回管理员地址

    function implementation() external view returns (address); // 返回实现地址

    function changeAdmin(address) external; // 更改管理员

    function upgradeTo(address) external; // 升级到新实现

    function upgradeToAndCall(address, bytes memory) external payable; // 升级到新实现并调用
}

/**
 * @dev 这个合约实现了一个可由管理员升级的代理。
 *
 * 为了避免 https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[代理选择器冲突]，
 * 这可能被用于攻击，此合约使用 https://blog.openzeppelin.com/the-transparent-proxy-pattern/[透明代理模式]。
 * 这种模式意味着两件相辅相成的事情：
 *
 * 1. 如果除管理员之外的任何账户调用代理，调用将被转发到实现，即使该调用匹配代理本身暴露的管理员函数之一。
 * 2. 如果管理员调用代理，它可以访问管理员函数，但其调用永远不会被转发到实现。如果管理员尝试调用实现上的函数，
 *    它将失败并显示"admin cannot fallback to proxy target"错误。
 *
 * 这些属性意味着管理员账户只能用于管理员操作，如升级代理或更改管理员，因此最好它是一个专用账户，
 * 不用于其他任何用途。这将避免在尝试从代理实现调用函数时因突然错误而头痛。
 *
 * 我们的建议是让专用账户成为{ProxyAdmin}合约的实例。如果以这种方式设置，
 * 您应该将`ProxyAdmin`实例视为代理的真正管理界面。
 *
 * 注意：此代理的真实接口是在`ITransparentUpgradeableProxy`中定义的。此合约不继承该接口，
 * 而是使用`_fallback`中的自定义调度机制隐式实现管理员函数。因此，编译器不会为此合约生成ABI。
 * 这对于完全实现透明性而不解码由代理和实现之间的选择器冲突引起的回退是必要的。
 *
 * 警告：不建议扩展此合约以添加额外的外部函数。如果这样做，由于上述说明，编译器不会检查没有选择器冲突。
 * 任何新函数与{ITransparentUpgradeableProxy}中声明的函数之间的选择器冲突将以新函数为准解决。
 * 这可能导致管理员操作无法访问，从而阻止可升级性。透明性也可能受到损害。
 */
contract TransparentUpgradeableProxy is ERC1967Proxy { // 继承ERC1967Proxy
    /**
     * @dev 初始化由`_admin`管理的可升级代理，由`_logic`处的实现支持，
     * 并可选择性地用`_data`初始化，如{ERC1967Proxy-constructor}中所述。
     */
    constructor(address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_); // 设置管理员
    }

    /**
     * @dev 内部使用的修饰符，除非发送者是管理员，否则将调用委托给实现。
     *
     * 注意：此修饰符已弃用，因为如果修改的函数有参数，且实现提供了具有相同选择器的函数，可能会导致问题。
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) { // 如果发送者是管理员
            _; // 执行函数体
        } else { // 否则
            _fallback(); // 回退到代理行为
        }
    }

    /**
     * @dev 如果调用者是管理员，在内部处理调用，否则透明地回退到代理行为
     */
    function _fallback() internal virtual override {
        if (msg.sender == _getAdmin()) { // 如果发送者是管理员
            bytes memory ret; // 返回数据
            bytes4 selector = msg.sig; // 获取函数选择器
            if (selector == ITransparentUpgradeableProxy.upgradeTo.selector) { // 如果是upgradeTo函数
                ret = _dispatchUpgradeTo(); // 调度upgradeTo
            } else if (selector == ITransparentUpgradeableProxy.upgradeToAndCall.selector) { // 如果是upgradeToAndCall函数
                ret = _dispatchUpgradeToAndCall(); // 调度upgradeToAndCall
            } else if (selector == ITransparentUpgradeableProxy.changeAdmin.selector) { // 如果是changeAdmin函数
                ret = _dispatchChangeAdmin(); // 调度changeAdmin
            } else if (selector == ITransparentUpgradeableProxy.admin.selector) { // 如果是admin函数
                ret = _dispatchAdmin(); // 调度admin
            } else if (selector == ITransparentUpgradeableProxy.implementation.selector) { // 如果是implementation函数
                ret = _dispatchImplementation(); // 调度implementation
            } else { // 如果是其他函数
                revert("TransparentUpgradeableProxy: admin cannot fallback to proxy target"); // 回退：管理员不能回退到代理目标
            }
            assembly {
                return(add(ret, 0x20), mload(ret)) // 返回编码的数据
            }
        } else { // 如果发送者不是管理员
            super._fallback(); // 调用父类的fallback
        }
    }

    /**
     * @dev 返回当前管理员。
     *
     * 提示：要获取此值，客户端可以使用 https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC调用
     * 直接从下面显示的存储槽（由EIP1967指定）读取。
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function _dispatchAdmin() private returns (bytes memory) {
        _requireZeroValue(); // 要求msg.value为0

        address admin = _getAdmin(); // 获取当前管理员
        return abi.encode(admin); // 编码并返回管理员地址
    }

    /**
     * @dev 返回当前实现。
     *
     * 提示：要获取此值，客户端可以使用 https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC调用
     * 直接从下面显示的存储槽（由EIP1967指定）读取。
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function _dispatchImplementation() private returns (bytes memory) {
        _requireZeroValue(); // 要求msg.value为0

        address implementation = _implementation(); // 获取当前实现
        return abi.encode(implementation); // 编码并返回实现地址
    }

    /**
     * @dev 更改代理的管理员。
     *
     * 发射{AdminChanged}事件。
     */
    function _dispatchChangeAdmin() private returns (bytes memory) {
        _requireZeroValue(); // 要求msg.value为0

        address newAdmin = abi.decode(msg.data[4:], (address)); // 从调用数据中解码新管理员地址
        _changeAdmin(newAdmin); // 更改管理员

        return ""; // 返回空字符串
    }

    /**
     * @dev 升级代理的实现。
     */
    function _dispatchUpgradeTo() private returns (bytes memory) {
        _requireZeroValue(); // 要求msg.value为0

        address newImplementation = abi.decode(msg.data[4:], (address)); // 从调用数据中解码新实现地址
        _upgradeToAndCall(newImplementation, bytes(""), false); // 升级到新实现，不调用初始化函数

        return ""; // 返回空字符串
    }

    /**
     * @dev 升级代理的实现，然后调用新实现中由`data`指定的函数，`data`应该是编码的函数调用。
     * 这对于在代理合约中初始化新的存储变量很有用。
     */
    function _dispatchUpgradeToAndCall() private returns (bytes memory) {
        (address newImplementation, bytes memory data) = abi.decode(msg.data[4:], (address, bytes)); // 从调用数据中解码新实现地址和数据
        _upgradeToAndCall(newImplementation, data, true); // 升级到新实现并调用初始化函数

        return ""; // 返回空字符串
    }

    /**
     * @dev 返回当前管理员。
     *
     * 注意：此函数已弃用。请使用{ERC1967Upgrade-_getAdmin}代替。
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin(); // 返回当前管理员
    }

    /**
     * @dev 为了保持此合约完全透明，所有`ifAdmin`函数都必须是payable的。此辅助函数在这里模拟
     * 某些代理函数不可支付，同时仍然允许值传递。
     */
    function _requireZeroValue() private {
        require(msg.value == 0); // 要求msg.value必须为0
    }
}