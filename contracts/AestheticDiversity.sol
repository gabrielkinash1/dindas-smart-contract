//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AestheticDiversity is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Pausable, IERC2981, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    Counters.Counter private _mintCount;

    Counters.Counter private _giveawayCount;

    uint256 public maxMintable = 265;

    uint256 public maxTokens = 250;

    uint256 public maxGiveaway = 15;

    uint256 public royaltiesPercentage = 7;

    uint256 public mintPrice;

    address payable public payableAddressOne;

    address payable public payableAddressTwo;

    string private _defaultBaseURI;

    bool public salesAvailable;

    constructor() ERC721("Aesthetic Diversity", "AEDV") {
        salesAvailable = false;
        _tokenIds.increment();
        _pause();
    }

    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You're not the owner");
        _burn(tokenId);
    }

    function mint(uint256 quantity) external payable whenNotPaused {
        uint256 amountMint = _mintCount.current();
        require(amountMint < maxMintable && ((amountMint + quantity) < maxMintable), "Mint limit exceeded!");
        require(salesAvailable, "Sales isn't public yet!");
        
        uint256 totalPrice = mintPrice * quantity;
        require(msg.value >= totalPrice, "Invalid amount!");

        payableAddressOne.transfer(totalPrice);

        uint256 tokenId = _tokenIds.current();
        for (uint256 i = 0; i < quantity; i++) {
            mintNFT(msg.sender, tokenId + i);
        }
    }

    function giveaway(address to, uint256 quantity) public onlyOwner {
        uint256 amountGiveaway = _giveawayCount.current();
        require(amountGiveaway < maxGiveaway && (amountGiveaway + quantity) < maxGiveaway, "Mint limit exceeded!");
        
        uint256 tokenId = _tokenIds.current();
        for (uint256 i = 0; i < quantity; i++) {
            giveNFT(to, tokenId + i);
        }
    }

    function mintNFT(address to, uint256 tokenId) internal {
        internalMint(to, tokenId);
        _mintCount.increment();
    }

    function giveNFT(address to, uint256 tokenId) internal {
        internalMint(to, tokenId);
        _giveawayCount.increment();
    }

    function internalMint(address to, uint256 tokenId) internal {
        require(tokenId <= maxTokens, "Token limit exceeded!");
        _safeMint(to, tokenId);
        _tokenIds.increment();
    }

    function togglePause() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function toggleSalesAvailable() public onlyOwner {
        salesAvailable = !salesAvailable;
    }

    function setBaseURI(string calldata newBaseURI) public onlyOwner {
        _defaultBaseURI = newBaseURI;
    }

    function setPayableAddressOne(address newAddress) public onlyOwner {
        payableAddressOne = payable(newAddress);
    }

    function setPayableAddressTwo(address newAddress) public onlyOwner {
        payableAddressTwo = payable(newAddress);
    }

    function setRoyaltiesPercentage(uint256 newPercentage) public onlyOwner {
        royaltiesPercentage = newPercentage;
    }

    function setMaxTokens(uint256 newMax) public onlyOwner {
        maxTokens = newMax;
    }

    function setMaxGiveaway(uint256 newMax) public onlyOwner {
        maxGiveaway = newMax;
        maxMintable = maxTokens - maxGiveaway;
    }

    function setMaxMintable(uint256 newMax) public onlyOwner {
        maxMintable = newMax;
        maxGiveaway = maxTokens - maxMintable;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function _baseURI() internal view override returns (string memory) {
        return _defaultBaseURI;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override (IERC2981) returns (address receiver, uint256 royaltyAmount) {
        uint256 royaltiesValue = (salePrice * royaltiesPercentage) / 100;
        return (payableAddressOne, royaltiesValue);
    }
}