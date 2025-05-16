// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/forge-std/src/Test.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../src/NFTMarketplace.sol";

contract MockNFT is ERC721 {

    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to_, uint256 tokenId_) external {
        _mint(to_, tokenId_);
    }

}  

contract NFTMarketplaceTest is Test {

    NFTMarketplace marketplace;
    MockNFT nft;
    address deployer = vm.addr(1);
    address user = vm.addr(2);
    uint256 tokenId = 0;

    function setUp() public {
        vm.startPrank(deployer);
        // Deployeamos el SC
        marketplace =  new NFTMarketplace();
        nft = new MockNFT();
        vm.stopPrank();

        vm.startPrank(user);
        nft.mint(user, 0);
        vm.stopPrank();
    }

    /**
     * @notice Checks that the NFT was correctly minted
     */
    function testMintNFT() public view {
        address ownerOf = nft.ownerOf(tokenId);
        assert(ownerOf == user);
    }

    /**
     * @notice Reverts if listing an NFT with price = 0.
     */
    function testShouldRevertIfPriceIsZero() public {
        vm.startPrank(user);

        vm.expectRevert("Price can not be 0");
        marketplace.listNFT(address(nft), tokenId, 0);

        vm.stopPrank();
    }

    /**
     * @notice Reverts if caller tries to list an NFT they don't own.
     */
    function testShouldRevertIfNotOwner() public {
        vm.startPrank(user);

        address user2_ = vm.addr(3);
        uint256 tokenId_ = 1;
        nft.mint(user2_, tokenId_);

        vm.expectRevert("You are not the owner of the NFT");
        marketplace.listNFT(address(nft), tokenId_, 1);

        vm.stopPrank();
    }

    /**
     * @notice Allows the owner to list their NFT successfully.
     * @dev Verifies that listing is stored in the mapping after listing.
     */
    function testListNFTCorrectly() public {
        vm.startPrank(user);

        (address sellerBefore,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT(address(nft), tokenId, 1 ether);
        (address sellerAfter,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user );

        vm.stopPrank();
    }

    /**
     * @notice Reverts if someone other than the lister tries to cancel the listing.
     */
    function testListShouldRevertIfNotOwner() public {
        vm.startPrank(user);

        (address sellerBefore,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT(address(nft), tokenId, 1 ether);
        (address sellerAfter,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user );

        vm.stopPrank();

        address user2 = vm.addr(3);
        vm.startPrank(user2);

        vm.expectRevert("You are not the listing owner");
        marketplace.cancelList(address(nft), tokenId);

        vm.stopPrank();
    }

    /**
     * @notice Allows the lister to cancel their listing successfully.
     */
    function testCancelListShouldWorkCorrectly() public {
        vm.startPrank(user);

        (address sellerBefore,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT(address(nft), tokenId, 1 ether);
        (address sellerAfter,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user );

        marketplace.cancelList(address(nft), tokenId);
        (address sellerAfter2,,,) = marketplace.listing(address(nft), tokenId);
        assert(sellerAfter2 == address(0));

        vm.stopPrank();
    }

    /**
     * @notice Reverts when trying to buy an NFT that is not listed.
     */
    function testCanNotBuyUnlistedNFT() public {
        address user2 = vm.addr(3);        
        vm.startPrank(user2);

        vm.expectRevert("Listing not exists");
        marketplace.buyNFT(address(nft), tokenId);

        vm.stopPrank();
    }

    /**
     * @notice Reverts when the buyer sends incorrect payment amount.
     * @dev List price is 1 ether, but buyer sends 1 wei less.
     */
    function testCanNotBuyWithIncorrectPay() public {
        vm.startPrank(user);

        uint256 price = 1e18;
        (address sellerBefore,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT(address(nft), tokenId, price);
        (address sellerAfter,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user );

        vm.stopPrank();

        address user2 = vm.addr(3);
        vm.deal(user2, price);
        vm.startPrank(user2);

        vm.expectRevert("Incorrect price");
        marketplace.buyNFT{value: price - 1}(address(nft), tokenId);

        vm.stopPrank();
    }

    /**
     * @notice Completes a successful NFT purchase.
     * @dev Verifies:
     * - The NFT is removed from the listing.
     * - Ownership of the NFT is transferred.
     * - Seller receives the correct amount of ETH.
     */
    function testShouldBuyNFTCorrectly() public {
        vm.startPrank(user);

        uint256 price = 1e18;
        (address sellerBefore,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT(address(nft), tokenId, price);
        (address sellerAfter,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user );
        nft.approve(address(marketplace), tokenId);

        vm.stopPrank();

        address user2 = vm.addr(3);
        vm.deal(user2, price);
        vm.startPrank(user2);

        (address sellerBefore2,,,) = marketplace.listing(address(nft), tokenId);
        address ownerBefore = nft.ownerOf(tokenId);
        uint256 balanceBefore = address(user).balance;
        marketplace.buyNFT{value: price}(address(nft), tokenId);
        (address sellerAfter2,,,) = marketplace.listing(address(nft), tokenId);
        address ownerAfter = nft.ownerOf(tokenId);
        uint256 balanceAfter = address(user).balance;

        assert(sellerBefore2 == user && sellerAfter2 == address(0));
        assert(ownerBefore == user && ownerAfter == user2);
        assert(balanceAfter == balanceBefore + price);

        vm.stopPrank();
    }

}