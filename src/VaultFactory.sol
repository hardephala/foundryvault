// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vault} from "./Vault.sol";
import {VaultNFT} from "./VaultNFT.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract VaultFactory {

    using SafeERC20 for IERC20;

    mapping(address => address) public vaults;
    VaultNFT public immutable VAULT_NFT;

    event VaultCreated(address indexed token, address indexed vault, address indexed owner, uint256 amount);
    event Deposited(address indexed token, address indexed vault, address indexed user, uint256 amount);

    constructor() {
        VAULT_NFT = new VaultNFT(address(this));
    }

    function deposit(address token, uint256 amount) external {
        require(token != address(0), "token=0");
        require(amount > 0, "amount=0");

        address vault = vaults[token];
        bool isNewVault = vault == address(0);

        if (isNewVault) {
            bytes32 salt = _saltFor(token);
            vault = address(
                new Vault{salt: salt}(token, address(this))
            );
            vaults[token] = vault;
        }

        IERC20(token).safeTransferFrom(msg.sender, vault, amount);
        Vault(vault).deposit(msg.sender, amount);

        if (isNewVault) {
            VAULT_NFT.mint(
                msg.sender,
                token,
                vault,
                amount,
                _safeSymbol(token),
                _safeName(token),
                _safeDecimals(token)
            );
            emit VaultCreated(token, vault, msg.sender, amount);
        }

        emit Deposited(token, vault, msg.sender, amount);
    }

    function computeVaultAddress(address token) external view returns (address predicted) {
        bytes32 salt = _saltFor(token);
        bytes memory creationCode = abi.encodePacked(
            type(Vault).creationCode,
            abi.encode(token, address(this))
        );
        bytes32 codeHash;
        assembly {
            codeHash := keccak256(add(creationCode, 0x20), mload(creationCode))
        }
        predicted = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(bytes1(0xff), address(this), salt, codeHash)
                    )
                )
            )
        );
    }

    function _saltFor(address token) internal pure returns (bytes32 salt) {
        assembly {
            mstore(0xff, token)
            salt := keccak256(0xff, 0x20)
        }
    }

    function _safeSymbol(address token) internal view returns (string memory) {
        try IERC20Metadata(token).symbol() returns (string memory value) {
            return value;
        } catch {
            return "UNKNOWN";
        }
    }

    function _safeName(address token) internal view returns (string memory) {
        try IERC20Metadata(token).name() returns (string memory value) {
            return value;
        } catch {
            return "Unknown Token";
        }
    }

    function _safeDecimals(address token) internal view returns (uint8) {
        try IERC20Metadata(token).decimals() returns (uint8 value) {
            return value;
        } catch {
            return 18;
        }
    }
}
