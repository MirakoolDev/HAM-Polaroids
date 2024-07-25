// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract HAMNFT is Initializable, ERC721URIStorageUpgradeable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {

    uint256 private _tokenIds;
    mapping(uint256 => uint256) public tokenTime;
    mapping(uint256 => uint256) public tokenMaze;
    uint256 private _mintFee;
    mapping(address => bool) private bannedAddresses;

    event Mint(address indexed to, uint256 indexed tokenId, string tokenURI, uint256 time, uint256 maze);
    event URI(string indexed tokenURI, uint256 indexed tokenId);

    error InsufficientFunds();
    error TokenDoesNotExist();
    error AddressBanned();

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 initialMintFee,
        address ownerAddress
    ) initializer public {
        __ERC721_init(name_, symbol_);
        __ERC721URIStorage_init();
        __Ownable_init(ownerAddress); // Pass owner address here
        __Pausable_init();
        __UUPSUpgradeable_init();

        _tokenIds = 0;
        _mintFee = initialMintFee;
    }

    modifier notBanned() {
        if (bannedAddresses[msg.sender]) revert AddressBanned();
        _;
    }

    function mint(
        string memory tokenURI,
        uint256 time,
        uint256 maze
    ) external payable whenNotPaused notBanned returns (uint256) {
        if (msg.value < _mintFee) revert InsufficientFunds();

        uint256 newTokenId = _tokenIds + 1;

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        tokenTime[newTokenId] = time;
        tokenMaze[newTokenId] = maze;

        _tokenIds = newTokenId;

        emit Mint(msg.sender, newTokenId, tokenURI, time, maze);
        emit URI(tokenURI, newTokenId);

        return newTokenId;
    }

    function setMintFee(uint256 newMintFee) external onlyOwner {
        _mintFee = newMintFee;
    }

    function getMintFee() external view returns (uint256) {
        return _mintFee;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner()).transfer(amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function banAddress(address user) external onlyOwner {
        bannedAddresses[user] = true;
    }

    function unbanAddress(address user) external onlyOwner {
        bannedAddresses[user] = false;
    }

    function isBanned(address user) external view returns (bool) {
        return bannedAddresses[user];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
