// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.25 <0.9.0;

import "forge-std/src/Test.sol";
import { NFTMarketplace } from "../src/NFTMarketplace.sol";
import { SimpleNFT, AnotherNFT } from "../src/SimpleNFT.sol";

contract NFTMarketplaceTest is Test {
    NFTMarketplace nftMarketplace;
    SimpleNFT simpleNFT;
    AnotherNFT anotherNFT;

    uint256 LIST_PRICE = 1e17; // 0.1 ETH

    function setUp() public {
        nftMarketplace = new NFTMarketplace();
        simpleNFT = new SimpleNFT();
        anotherNFT = new AnotherNFT();

        /**
         * Assuming that:
         * address 1 is Alice as seller
         * address 2 is Bob as buyer
         * SimpleNFT is the PudgyPenguin NFT
         * AnotherNFT is the BoredApe NFT
         */
    }

    function testFail_ListNFTWithNonNFT() public {
        simpleNFT.safeTransferFrom(address(this), address(1), 1);
        assertEq(simpleNFT.ownerOf(1), address(1));

        vm.startPrank(address(1));
        bytes memory encodedPrice = abi.encode(LIST_PRICE);
        nftMarketplace.onERC721Received(address(1), address(1), 1, encodedPrice);
        vm.stopPrank();
    }

    function testFail_ListNFTWithoutSpecifyPrice() public {
        simpleNFT.safeTransferFrom(address(this), address(1), 1);
        assertEq(simpleNFT.ownerOf(1), address(1));

        vm.startPrank(address(1));
        nftMarketplace.onERC721Received(address(1), address(1), 1, "");
        vm.stopPrank();
    }

    function test_ListNFT() public {
        simpleNFT.safeTransferFrom(address(this), address(1), 1);
        assertEq(simpleNFT.ownerOf(1), address(1));

        vm.startPrank(address(1));
        bytes memory encodedPrice = abi.encode(LIST_PRICE);
        simpleNFT.safeTransferFrom(address(1), address(nftMarketplace), 1, encodedPrice);
        assertEq(simpleNFT.ownerOf(1), address(nftMarketplace));
        (uint256 price, address seller) = nftMarketplace.nftSales(simpleNFT, 1);
        assertEq(price, LIST_PRICE);
        assertEq(seller, address(1));
    }

    function testFail_WithdrawNFTWithNonSeller() public {
        simpleNFT.safeTransferFrom(address(this), address(1), 1);
        assertEq(simpleNFT.ownerOf(1), address(1));

        vm.startPrank(address(1));
        nftMarketplace.withdraw(simpleNFT, 1);
        vm.stopPrank();
    }
}
