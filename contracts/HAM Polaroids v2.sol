// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract HAMNFT is ERC721URIStorage, Ownable {
    using ECDSA for bytes32;

    uint256 private _tokenIds;
    mapping(uint256 => uint256) public tokenTime; // Public for read access
    mapping(uint256 => uint256) public tokenMaze; // Changed to uint256
    uint256 private _mintFee; // Fee to mint a token
    address public signer;

    event Mint(address indexed to, uint256 indexed tokenId, string tokenURI, uint256 time, uint256 maze);
    event URI(string indexed tokenURI, uint256 indexed tokenId);

    error InsufficientFunds();
    error InvalidSignature();
    error TokenDoesNotExist();

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialMintFee,
        address ownerAddress,
        address initialSigner
    ) ERC721(name_, symbol_) Ownable(ownerAddress) {
        _tokenIds = 0;
        _mintFee = initialMintFee;
        signer = initialSigner;
        transferOwnership(ownerAddress);
    }

    function mint(
        string memory tokenURI,
        uint256 time,
        uint256 maze,
        bytes calldata signature
    ) external payable returns (uint256) {
        // Check if the sent value is at least the mint fee
        if (msg.value < _mintFee) revert InsufficientFunds();

        // Verify the signature
        if (!verifyMintSignature(tokenURI, time, maze, msg.sender, signature)) revert InvalidSignature();

        uint256 newTokenId = _tokenIds + 1;

        // Safe minting of the new token
        _safeMint(msg.sender, newTokenId);
        // Setting the token URI
        _setTokenURI(newTokenId, tokenURI);

        // Storing additional information about the token
        tokenTime[newTokenId] = time;
        tokenMaze[newTokenId] = maze;

        // Updating the token ID counter
        _tokenIds = newTokenId;

        // Emitting the Mint event
        emit Mint(msg.sender, newTokenId, tokenURI, time, maze);
        emit URI(tokenURI, newTokenId);

        return newTokenId;
    }

    function verifyMintSignature(
        string memory tokenURI,
        uint256 time,
        uint256 maze,
        address to,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 message = toEthSignedMessageHash(keccak256(abi.encodePacked(tokenURI, time, maze, to)));
        return message.recover(signature) == signer;
    }

    function toEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function setMintFee(uint256 newMintFee) external onlyOwner {
        _mintFee = newMintFee;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner()).transfer(amount);
    }

    function updateSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }
}
