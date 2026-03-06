// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract VaultNFT is ERC721 {
    using Strings for uint256;
    uint256 public nextId;

    address public factory;

    struct DepositInfo {
        address token;
        address vault;
        uint256 amount;
        string tokenSymbol;
        string tokenName;
        uint8 tokenDecimals;
        uint256 createdAt;
        uint256 createdBlock;
    }

    mapping(uint256 => DepositInfo) public deposits;

    modifier onlyFactory() {
        _onlyFactory();
        _;
    }

    function _onlyFactory() internal view {
        require(msg.sender == factory, "not factory");
    }

    constructor(address _factory)
        ERC721("Vault Deposit Receipt", "VDR")
    {
        factory = _factory;
    }

    function mint(
        address user,
        address token,
        address vault,
        uint256 amount,
        string memory tokenSymbol,
        string memory tokenName,
        uint8 tokenDecimals
    ) external onlyFactory returns (uint256 id) {
        id = ++nextId;

        _mint(user, id);

        deposits[id] = DepositInfo({
            token: token,
            vault: vault,
            amount: amount,
            tokenSymbol: tokenSymbol,
            tokenName: tokenName,
            tokenDecimals: tokenDecimals,
            createdAt: block.timestamp,
            createdBlock: block.number
        });
    }

    function generateSvg(uint256 id) internal view returns (string memory) {
        DepositInfo memory info = deposits[id];
        return string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 350 200' width='350' height='200' style='background-color:black;pointer-events:none;'>",
                "<rect width='350' height='200' fill='black'/>",
                "<text x='10' y='20' fill='white' font-family='monospace' font-size='14'>Vault Receipt NFT</text>",
                "<text x='10' y='45' fill='white' font-family='monospace' font-size='12'>Token:</text>",
                "<text x='85' y='45' fill='white' font-family='monospace' font-size='12'>",
                info.tokenSymbol,
                "</text>",
                "<text x='10' y='65' fill='white' font-family='monospace' font-size='12'>TokenName:</text>",
                "<text x='105' y='65' fill='white' font-family='monospace' font-size='11'>",
                info.tokenName,
                "</text>",
                "<text x='10' y='85' fill='white' font-family='monospace' font-size='11'>TokenAddr:</text>",
                "<text x='105' y='85' fill='#00ff00' font-family='monospace' font-size='10'>",
                Strings.toHexString(uint160(info.token), 20),
                "</text>",
                "<text x='10' y='105' fill='white' font-family='monospace' font-size='12'>Vault:</text>",
                "<text x='85' y='105' fill='#00ff00' font-family='monospace' font-size='10'>",
                Strings.toHexString(uint160(info.vault), 20),
                "</text>",
                "<text x='10' y='125' fill='white' font-family='monospace' font-size='12'>Amount:</text>",
                "<text x='85' y='125' fill='#ffff00' font-family='monospace' font-size='12'>",
                info.amount.toString(),
                "</text>",
                "<text x='10' y='145' fill='white' font-family='monospace' font-size='12'>Decimals:</text>",
                "<text x='100' y='145' fill='#ffff00' font-family='monospace' font-size='12'>",
                uint256(info.tokenDecimals).toString(),
                "</text>",
                "<text x='10' y='165' fill='white' font-family='monospace' font-size='12'>Block:</text>",
                "<text x='75' y='165' fill='#ffff00' font-family='monospace' font-size='12'>",
                info.createdBlock.toString(),
                "</text>",
                "</svg>"
            )
        );
    }

    function tokenURI(uint256 id)
        public view override returns (string memory) {
        string memory svg = generateSvg(id);

        string memory image = Base64.encode(bytes(svg));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"Vault Deposit Receipt #',
                        id.toString(),
                        '",',
                        '"description":"Receipt NFT for vault deposits",',
                        '"image":"data:image/svg+xml;base64,',
                        image,
                        '"}'
                    )
                )
            )
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                json
            )
        );
    }
}
