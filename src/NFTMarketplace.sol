// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {

    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
    }
    mapping(address => mapping(uint256 => Listing)) public listing; 

    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NFTCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event NFTSold(address indexed buyer, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 price);

    constructor() {}

    /**
     * @notice Lists an NFT on the marketplace with a given price
     * @dev Requires the caller to be the owner of the NFT
     * @param nftAddress_ Address of the ERC721 contract
     * @param tokenId_ Token ID of the NFT to list
     * @param price_ Token price
     * Emits the NFTListed event
     */
    function listNFT(address nftAddress_, uint256 tokenId_, uint256 price_) external nonReentrant {
        require(price_ > 0, "Price can not be 0");
        address owner_ = IERC721(nftAddress_).ownerOf(tokenId_);
        require(owner_ == msg.sender, "You are not the owner of the NFT");

        Listing memory listing_ = Listing({
            seller: msg.sender, 
            nftAddress: nftAddress_, 
            tokenId: tokenId_, 
            price: price_
        });
        listing[nftAddress_][tokenId_] = listing_;

        emit NFTListed(msg.sender, nftAddress_, tokenId_, price_);
    }

    /**
     * @notice Purchases a listed NFT by paying the exact listing price
     * @dev Requires the NFT to be listed and `msg.value` to match the price
     * @param nftAddress_ Address of the ERC721 contract
     * @param tokenId_ Token ID of the NFT to list
     * Emits the NFTSold event
     */
    function buyNFT(address nftAddress_, uint256 tokenId_) external payable nonReentrant {
        Listing memory listing_ = listing[nftAddress_][tokenId_];
        require(listing_.price > 0, "Listing not exists");  
        require(msg.value == listing_.price, "Incorrect price");

        delete listing[nftAddress_][tokenId_];

        IERC721(nftAddress_).safeTransferFrom(listing_.seller, msg.sender, listing_.tokenId);

        (bool success, ) = listing_.seller.call{value: msg.value}("");
        require(success, "Transfer failed");

        emit NFTSold(msg.sender, listing_.seller, listing_.nftAddress, listing_.tokenId, listing_.price);
    }

    /**
     * @notice Cancels an active NFT listing
     * @dev Only the seller who created the listing can cancel it
     * @param nftAddress_ Address of the ERC721 contract
     * @param tokenId_ Token ID of the NFT to delist
     * Emits a NFTCanceled event
     */
    function cancelList(address nftAddress_, uint256 tokenId_) external nonReentrant {
        Listing memory listing_ = listing[nftAddress_][tokenId_];
        require(listing_.seller == msg.sender, "You are not the listing owner");

        delete listing[nftAddress_][tokenId_];

        emit NFTCanceled(msg.sender, nftAddress_, tokenId_);
    }


}