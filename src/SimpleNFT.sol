// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.25 <0.9.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleNFT is ERC721, Ownable {
    constructor() ERC721("SimpleNFT", "SNFT") Ownable(msg.sender) {
        _mint(msg.sender, 1);
    }

    uint256 public count = 2;

    event NFTMinted(address indexed to, uint256 indexed tokenId);

    function mint(address to) external onlyOwner {
        _mint(to, count);
        count++;
        emit NFTMinted(to, count);
    }
}

contract AnotherNFT is ERC721, Ownable {
    constructor() ERC721("AnotherNFT", "ANFT") Ownable(msg.sender) {
        _mint(msg.sender, 1);
    }

    uint256 public count = 2;

    event NFTMinted(address indexed to, uint256 indexed tokenId);

    function mint(address to) external onlyOwner {
        _mint(to, count);
        count++;
        emit NFTMinted(to, count);
    }
}
