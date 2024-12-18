// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.25 <0.9.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "forge-std/src/console2.sol";

contract NFTMarketplace is IERC721Receiver {
    constructor() { }

    struct NFTSale {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => NFTSale)) public nftSales;

    error AccountError(string message);
    error NFTError(string message);

    event NFTSaleCreated(address indexed nft, address seller, uint256 indexed tokenId, uint256 price);
    event NFTSold(address indexed nft, address seller, address buyer, uint256 indexed tokenId, uint256 price);
    event NFTWithdrawn(address indexed nft, address seller, uint256 indexed tokenId);

    function withdraw(address _nft, uint256 _tokenId) external {
        if (nftSales[_nft][_tokenId].seller != msg.sender) {
            revert AccountError("You are not the seller of this NFT");
        }

        delete nftSales[_nft][_tokenId];
        IERC721(_nft).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit NFTWithdrawn(_nft, msg.sender, _tokenId);
    }

    function buy(address _nft, uint256 _tokenId) external payable {
        NFTSale memory sale = nftSales[_nft][_tokenId];
        if (sale.seller == address(0)) {
            revert NFTError("NFT is not for sale");
        }
        if (msg.value < sale.price) {
            revert AccountError("Insufficient funds");
        }

        delete nftSales[_nft][_tokenId];
        (bool success,) = sale.seller.call{ value: sale.price }("");
        if (!success) {
            revert AccountError("Failed to send funds to seller");
        }

        IERC721(_nft).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit NFTSold(_nft, sale.seller, msg.sender, _tokenId, sale.price);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        override
        returns (bytes4)
    {
        console2.log(_operator); // Remove warning variable not used :D
        if (!IERC721(msg.sender).supportsInterface(type(IERC721).interfaceId)) {
            // Check if the contract supports ERC721 interface
            revert NFTError("Contract does not support ERC721 interface");
        }
        if (_data.length == 0) {
            revert NFTError("Price is required");
        }
        uint256 price = abi.decode(_data, (uint256));
        nftSales[msg.sender][_tokenId] = NFTSale(price, _from);

        emit NFTSaleCreated(msg.sender, _from, _tokenId, price);
        return this.onERC721Received.selector;
    }
}
