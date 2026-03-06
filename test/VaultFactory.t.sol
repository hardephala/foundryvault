// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {VaultFactory} from "../src/VaultFactory.sol";
import {Vault} from "../src/Vault.sol";
import {VaultNFT} from "../src/VaultNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract VaultFactoryTest is Test {
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant BINANCE_WHALE = 0x28C6c06298d514Db089934071355E5743bf21d60;// Impersonating Binance hot wallet with large USDC and WETH balances for testing

    VaultFactory factory;
    VaultNFT vaultNft;

    function setUp() public {
        vm.createSelectFork("https://ethereum.publicnode.com");

        factory = new VaultFactory();
        vaultNft = VaultNFT(address(factory.VAULT_NFT()));
    }

    function _fund(address token, uint256 amount) internal {
        vm.startPrank(BINANCE_WHALE);
        require(IERC20(token).transfer(address(this), amount), "whale transfer failed");
        vm.stopPrank();
    }

    function testFirstDepositDeploysVaultAndMintsNft() public {
        uint256 amount = 1_000e6;
        _fund(USDC, amount);

        IERC20(USDC).approve(address(factory), amount);

        address predicted = factory.computeVaultAddress(USDC);
        factory.deposit(USDC, amount);

        address vault = factory.vaults(USDC);
        assertEq(vault, predicted, "create2 address mismatch");
        assertEq(IERC20(USDC).balanceOf(vault), amount, "vault token balance mismatch");
        assertEq(Vault(vault).totalDeposits(), amount, "vault accounting mismatch");
        assertEq(vaultNft.ownerOf(1), address(this), "nft owner mismatch");

        (address infoToken, address infoVault, uint256 infoAmount, , , , , ) = vaultNft.deposits(1);
        assertEq(infoToken, USDC, "nft token mismatch");
        assertEq(infoVault, vault, "nft vault mismatch");
        assertEq(infoAmount, amount, "nft amount mismatch");
        console.log(vaultNft.tokenURI(1));

    }

    function testSecondDepositSameTokenReusesVaultAndNoNewNft() public {
        uint256 amount1 = 600e6;
        uint256 amount2 = 400e6;
        _fund(USDC, amount1 + amount2);

        IERC20(USDC).approve(address(factory), amount1 + amount2);

        factory.deposit(USDC, amount1);
        address vault1 = factory.vaults(USDC);
        assertEq(vaultNft.nextId(), 1, "first mint missing");

        factory.deposit(USDC, amount2);
        address vault2 = factory.vaults(USDC);

        assertEq(vault1, vault2, "vault should be reused");
        assertEq(vaultNft.nextId(), 1, "should not mint second nft for same token");
        assertEq(Vault(vault1).totalDeposits(), amount1 + amount2, "totalDeposits mismatch");
        assertEq(Vault(vault1).balances(address(this)), amount1 + amount2, "user balance mismatch");
    }

    function testDifferentTokensDeployDifferentVaults() public {
        uint256 usdcAmount = 100e6;
        uint256 wethAmount = 1 ether;
        _fund(USDC, usdcAmount);
        _fund(WETH, wethAmount);

        IERC20(USDC).approve(address(factory), usdcAmount);
        IERC20(WETH).approve(address(factory), wethAmount);

        factory.deposit(USDC, usdcAmount);
        factory.deposit(WETH, wethAmount);

        address usdcVault = factory.vaults(USDC);
        address wethVault = factory.vaults(WETH);
        assertTrue(usdcVault != address(0), "usdc vault missing");
        assertTrue(wethVault != address(0), "weth vault missing");
        assertTrue(usdcVault != wethVault, "vaults should differ by token");
        assertEq(vaultNft.nextId(), 2, "one nft per new token vault expected");
    }

    function testTokenUriIsOnchainDataUri() public {
        uint256 amount = 100e6;
        _fund(USDC, amount);

        IERC20(USDC).approve(address(factory), amount);

        factory.deposit(USDC, amount);

        string memory uri = vaultNft.tokenURI(1);
        bytes memory prefix = bytes("data:application/json;base64,");
        bytes memory uriBytes = bytes(uri);
        assertGe(uriBytes.length, prefix.length, "tokenURI too short");
        for (uint256 i; i < prefix.length; i++) {
            assertEq(uriBytes[i], prefix[i], "tokenURI prefix mismatch");
        }
    }
    function testPredictedVaultAddressMatchesDeployed() public {

        address token = USDC;

        // Step 1: Compute predicted address
        address predicted = factory.computeVaultAddress(token);

        // Step 2: Deposit (this deploys vault)
        uint256 amount = 1000e6;

        //address whale = 0x55fe002aeff02f77364de339a1292923a15844b8;

        vm.startPrank(BINANCE_WHALE);
        require(IERC20(token).transfer(address(this), amount), "Transfer failed");
        vm.stopPrank();

        IERC20(token).approve(address(factory), amount);

        factory.deposit(token, amount);

        // Step 3: Get actual deployed vault
        address actual = factory.vaults(token);

        // Step 4: Verify addresses match
        assertEq(predicted, actual);
    }
}
