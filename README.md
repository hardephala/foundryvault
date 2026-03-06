# Foundry Vault System

A decentralized token vault system built with Solidity and Foundry, allowing users to deposit ERC20 tokens and receive NFT receipts that visually represent their deposits.

## Project Overview

The Foundry Vault System is a smart contract suite that provides a secure way to deposit and manage ERC20 tokens. When users deposit tokens, they receive an ERC721 NFT as a receipt that encodes all deposit information in an SVG-based visual representation.

### Key Features

- **Multi-token Support**: Users can deposit any ERC20 token
- **NFT Receipts**: Automatic NFT generation on deposit with encoded deposit metadata
- **Deterministic Vault Creation**: Uses CREATE2 for predictable vault addresses based on token
- **Gas Optimized**: Minimal storage and computation overhead
- **SVG-based Metadata**: NFTs feature visually encoded deposit information

## Architecture

### System Components

```
VaultFactory (Main Entry Point)
    ├── Manages all vault deployments
    ├── Handles token deposits
    ├── Creates NFT receipts
    └── Uses CREATE2 for deterministic addresses

    ↓
    
Vault (Token-specific contracts)
    ├── One vault per ERC20 token
    ├── Stores user balances
    ├── Tracks total deposits
    └── Only callable by VaultFactory

    ↓
    
VaultNFT (ERC721 Receipt NFTs)
    ├── Generates receipt NFTs
    ├── Encodes deposit metadata
    ├── Renders SVG-based visual NFTs
    └── Only callable by VaultFactory
```

### Smart Contract Details

#### 1. **VaultFactory.sol**
The main entry point for the system. Responsible for:
- Creating new vaults for tokens (using CREATE2 for deterministic addresses)
- Handling user deposits
- Minting receipt NFTs
- Extracting token metadata (name, symbol, decimals)
- Computing vault addresses without deployment

**Key Functions:**
- `deposit(address token, uint256 amount)`: Deposit ERC20 tokens
- `computeVaultAddress(address token)`: Predict vault address before deployment
- `_saltFor(address token)`: Generate deterministic salt for CREATE2
- `_safeSymbol/Name/Decimals()`: Safely fetch token metadata with fallbacks

#### 2. **Vault.sol**
Individual vault contracts for each ERC20 token.

**Responsibilities:**
- Store user balances per token
- Track total deposits
- Only accept calls from VaultFactory (via modifier)

**Key State:**
- `TOKEN`: The ERC20 token this vault manages
- `FACTORY`: The VaultFactory contract address
- `balances`: Mapping of user addresses to deposit amounts
- `totalDeposits`: Total amount of tokens held

#### 3. **VaultNFT.sol**
ERC721-based receipt contract that generates visual NFTs.

**Deposit Info Stored:**
- Token address, symbol, name, decimals
- Vault address
- Deposit amount
- Creation timestamp and block number

**SVG Rendering:**
- Black background with monospace font
- Color-coded information:
  - White text for labels
  - Green (#00ff00) for addresses
  - Yellow (#ffff00) for numerical values
- Non-selectable text (pointer-events: none)

**Key Functions:**
- `mint()`: Create new receipt NFT
- `generateSvg()`: Render SVG from deposit data
- `tokenURI()`: Return base64-encoded metadata

## Implementation Details

### Deposit Flow

```
User calls VaultFactory.deposit(token, amount)
    ↓
1. Check if vault exists for token
    ↓
2. If new vault:
   - Calculate salt from token address
   - Deploy Vault contract using CREATE2
   - Store vault mapping
    ↓
3. Transfer tokens from user to vault
    ↓
4. Call vault.deposit() to update balances
    ↓
5. If new vault:
   - Fetch token metadata safely
   - Call VaultNFT.mint() to create receipt
   - Emit VaultCreated event
    ↓
6. Emit Deposited event
```

### Deterministic Vault Addresses

Vaults use CREATE2 with a token-based salt to ensure:
- Same token always deploys to same address
- Address can be computed off-chain before deployment
- Multiple deployments of same token are prevented

**Salt Calculation:**
```solidity
bytes32 salt = keccak256(abi.encodePacked(token))
```

### Safe Token Metadata Extraction

The system safely handles tokens that don't implement optional ERC20Metadata interface:
- `symbol()` → fallback: "UNKNOWN"
- `name()` → fallback: "Unknown Token"
- `decimals()` → fallback: 18

### NFT Receipt Generation

Each NFT:
1. Stores complete deposit information in contract state
2. Generates SVG on-demand when `tokenURI()` is called
3. Encodes SVG as base64 image data
4. Wraps metadata in JSON and base64 encodes
5. Returns as data URI for direct wallet display

## Gas Optimization

- **Immutable addresses**: TOKEN and FACTORY stored as immutable
- **Efficient storage**: Only essential deposit info stored
- **SafeERC20**: Uses OpenZeppelin's battle-tested token transfer
- **Assembly usage**: Optimized salt and address computation
- **Lazy metadata**: SVG generated only when needed

## Events

- `VaultCreated(address indexed token, address indexed vault, address indexed owner, uint256 amount)`: New vault created
- `Deposited(address indexed token, address indexed vault, address indexed user, uint256 amount)`: Token deposited

## Dependencies

- **@openzeppelin/contracts**: ERC721, ERC20 utilities, Base64 encoding
- **forge-std**: Foundry testing library

## Security Considerations

- ✅ Only factory can mint NFTs (onlyFactory modifier)
- ✅ Only factory can receive deposits in vaults
- ✅ Safe token transfers using SafeERC20
- ✅ No reentrancy risks (no external calls to untrusted contracts)
- ✅ Deterministic addresses prevent deployment collisions

## Future Enhancements

- Withdrawal functionality
- Deposit history/events querying
- Multi-sig approval for large deposits
- Yield generation for vaults
- NFT metadata updates on withdrawal

## Testing

Run tests with:
```bash
forge test
```

Test files:
- `test/VaultFactory.t.sol`: Factory creation and deposit tests
- `test/VaultNFT.t.sol`: NFT generation tests

## Deployment

```bash
forge create src/VaultFactory.sol:VaultFactory --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

## License

MIT
