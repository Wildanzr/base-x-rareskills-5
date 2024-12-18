// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.25 <0.9.0;

import "forge-std/src/Test.sol";
import { NFTMarketplace } from "../src/NFTMarketplace.sol";
import { SimpleNFT, AnotherNFT } from "../src/SimpleNFT.sol";

contract NFTMarketplaceTest is Test {
    NFTMarketplace nftMarketplace;
    SimpleNFT simpleNFT;
    AnotherNFT anotherNFT;

    uint256 LIST_PRICE = 0.1 ether;
    uint256 LOWER_BUY_PRICE = 0.05 ether;

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
        (uint256 price, address seller) = nftMarketplace.nftSales(address(simpleNFT), 1);
        assertEq(price, LIST_PRICE);
        assertEq(seller, address(1));
        vm.stopPrank();
    }

    function test_ListMultipleNFTs() public {
        simpleNFT.safeTransferFrom(address(this), address(1), 1);
        anotherNFT.safeTransferFrom(address(this), address(2), 1);
        assertEq(simpleNFT.ownerOf(1), address(1));
        assertEq(anotherNFT.ownerOf(1), address(2));

        vm.startPrank(address(1));
        bytes memory encodedPrice = abi.encode(LIST_PRICE);
        simpleNFT.safeTransferFrom(address(1), address(nftMarketplace), 1, encodedPrice);
        assertEq(simpleNFT.ownerOf(1), address(nftMarketplace));
        (uint256 price, address seller) = nftMarketplace.nftSales(address(simpleNFT), 1);
        assertEq(price, LIST_PRICE);
        assertEq(seller, address(1));
        vm.stopPrank();

        vm.startPrank(address(2));
        anotherNFT.safeTransferFrom(address(2), address(nftMarketplace), 1, encodedPrice);
        assertEq(anotherNFT.ownerOf(1), address(nftMarketplace));
        (price, seller) = nftMarketplace.nftSales(address(anotherNFT), 1);
        assertEq(price, LIST_PRICE);
        assertEq(seller, address(2));
        vm.stopPrank();
    }

    function testFail_WithdrawNFTWithNonSeller() public {
        simpleNFT.safeTransferFrom(address(this), address(1), 1);
        assertEq(simpleNFT.ownerOf(1), address(1));

        vm.startPrank(address(1));
        nftMarketplace.withdraw(address(simpleNFT), 1);
        vm.stopPrank();
    }

    function test_WithdrawNFT() public {
        simpleNFT.safeTransferFrom(address(this), address(1), 1);
        assertEq(simpleNFT.ownerOf(1), address(1));

        vm.startPrank(address(1));
        bytes memory encodedPrice = abi.encode(LIST_PRICE);
        simpleNFT.safeTransferFrom(address(1), address(nftMarketplace), 1, encodedPrice);
        assertEq(simpleNFT.ownerOf(1), address(nftMarketplace));

        nftMarketplace.withdraw(address(simpleNFT), 1);
        assertEq(simpleNFT.ownerOf(1), address(1));
        vm.stopPrank();
    }

    function testFail_BuyNFTWithoutListed() public {
        vm.startPrank(address(2));
        nftMarketplace.buy(address(simpleNFT), 1);
        vm.stopPrank();
    }

    function testFail_BuyNFTWithInsufficientFunds() public {
        simpleNFT.safeTransferFrom(address(this), address(1), 1);
        assertEq(simpleNFT.ownerOf(1), address(1));

        vm.startPrank(address(1));
        bytes memory encodedPrice = abi.encode(LIST_PRICE);
        simpleNFT.safeTransferFrom(address(1), address(nftMarketplace), 1, encodedPrice);
        assertEq(simpleNFT.ownerOf(1), address(nftMarketplace));
        vm.stopPrank();

        vm.startPrank(address(2));
        nftMarketplace.buy{ value: LOWER_BUY_PRICE }(address(simpleNFT), 1);
        vm.stopPrank();
    }

    function test_BuyNFT() public {
        simpleNFT.safeTransferFrom(address(this), address(1), 1);
        assertEq(simpleNFT.ownerOf(1), address(1));

        vm.startPrank(address(1));
        bytes memory encodedPrice = abi.encode(LIST_PRICE);
        simpleNFT.safeTransferFrom(address(1), address(nftMarketplace), 1, encodedPrice);
        assertEq(simpleNFT.ownerOf(1), address(nftMarketplace));
        vm.stopPrank();

        vm.startPrank(address(2));
        vm.deal(address(2), 1 ether);
        uint256 sellerBalanceBefore = address(1).balance;
        nftMarketplace.buy{ value: 0.1 ether }(address(simpleNFT), 1);
        assertEq(simpleNFT.ownerOf(1), address(2));
        uint256 sellerBalanceAfter = address(1).balance;
        assertEq(sellerBalanceBefore, sellerBalanceAfter - LIST_PRICE);
        vm.stopPrank();
    }

    function testFail_WithdrawNFTAfterSold() public {
        simpleNFT.safeTransferFrom(address(this), address(1), 1);
        assertEq(simpleNFT.ownerOf(1), address(1));

        vm.startPrank(address(1));
        bytes memory encodedPrice = abi.encode(LIST_PRICE);
        simpleNFT.safeTransferFrom(address(1), address(nftMarketplace), 1, encodedPrice);
        assertEq(simpleNFT.ownerOf(1), address(nftMarketplace));
        vm.stopPrank();

        vm.startPrank(address(2));
        vm.deal(address(2), 1 ether);
        nftMarketplace.buy{ value: 0.1 ether }(address(simpleNFT), 1);
        vm.stopPrank();

        vm.startPrank(address(1));
        nftMarketplace.withdraw(address(simpleNFT), 1);
        vm.stopPrank();
    }
}
