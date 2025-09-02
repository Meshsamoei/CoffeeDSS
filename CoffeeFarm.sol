// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CoffeeFarm is ERC721, Ownable {
    uint256 private _tokenIds;

    struct Farmer {
        string nationalId;
        address wallet;
        bool registered;
    }

    struct Harvest {
        string nationalId;
        uint256 quantityKg;   // in kilograms
        string qualityGrade;  // e.g. AA, AB, PB
        string harvestDate;
        string fertilizerUsed;
        string certifications; // e.g. FairTrade, Organic
    }

    mapping(string => Farmer) private farmers;
    mapping(uint256 => Harvest) public harvests;
    mapping(address => bool) public cooperatives;

    event FarmerRegistered(string nationalId, address wallet);
    event HarvestMinted(uint256 indexed tokenId, string nationalId, uint256 quantityKg, string qualityGrade);
    event CooperativeAdded(address coop);
    event CooperativeRemoved(address coop);

    constructor() ERC721("CoffeeHarvestNFT", "CHNFT") Ownable(msg.sender) {}

    // --- Cooperative Management ---
    modifier onlyCooperative() {
        require(cooperatives[msg.sender], "Not authorized");
        _;
    }

    function addCooperative(address coop) public onlyOwner {
        require(coop != address(0), "Invalid coop address");
        cooperatives[coop] = true;
        emit CooperativeAdded(coop);
    }

    function removeCooperative(address coop) public onlyOwner {
        cooperatives[coop] = false;
        emit CooperativeRemoved(coop);
    }

    // --- Farmer Registration ---
    function registerFarmer(string memory _nationalId, address _wallet) public onlyCooperative {
        require(!farmers[_nationalId].registered, "Farmer already registered");
        require(_wallet != address(0), "Invalid wallet address");

        farmers[_nationalId] = Farmer({
            nationalId: _nationalId,
            wallet: _wallet,
            registered: true
        });

        emit FarmerRegistered(_nationalId, _wallet);
    }

    function getFarmer(string memory _nationalId) public view returns (string memory, address, bool) {
        Farmer memory f = farmers[_nationalId];
        return (f.nationalId, f.wallet, f.registered);
    }

    // --- Mint Coffee Harvest NFT ---
    function mintHarvest(
        string memory _nationalId,
        uint256 _quantityKg,
        string memory _qualityGrade,
        string memory _harvestDate,
        string memory _fertilizerUsed,
        string memory _certifications
    ) public onlyCooperative returns (uint256) {
        require(farmers[_nationalId].registered, "Farmer not registered");

        _tokenIds++;
        uint256 newTokenId = _tokenIds;

        address farmerWallet = farmers[_nationalId].wallet;
        _safeMint(farmerWallet, newTokenId);

        harvests[newTokenId] = Harvest({
            nationalId: _nationalId,
            quantityKg: _quantityKg,
            qualityGrade: _qualityGrade,
            harvestDate: _harvestDate,
            fertilizerUsed: _fertilizerUsed,
            certifications: _certifications
        });

        emit HarvestMinted(newTokenId, _nationalId, _quantityKg, _qualityGrade);

        return newTokenId;
    }

    // --- Fetch harvest details ---
    function getHarvest(uint256 tokenId) public view returns (Harvest memory) {
        return harvests[tokenId];
    }

    // --- Helper: Get all NFTs owned by a farmer ---
    function getFarmerHarvests(string memory _nationalId) public view returns (uint256[] memory) {
        Farmer memory f = farmers[_nationalId];
        require(f.registered, "Farmer not registered");

        uint256 balance = balanceOf(f.wallet);
        uint256[] memory tokens = new uint256[](balance);

        uint256 counter = 0;
        for (uint256 i = 1; i <= _tokenIds; i++) {
            if (ownerOf(i) == f.wallet) {
                tokens[counter] = i;
                counter++;
            }
        }
        return tokens;
    }
}
