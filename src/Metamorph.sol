// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC721} from "solady/tokens/ERC721.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibString} from "solady/utils/LibString.sol";

contract Metamorph is ERC721, Ownable {
    using LibString for uint256;
    using LibString for string;

    error Locked();
    error TransferFailed();
    error SupplyCapReached();
    error InsufficientPayment();

    event URILocked();
    event MintOpened();
    event MintClosed();
    event SupplyUpdate(uint16 indexed newMaxSupply);
    event UpdateBaseURI(string indexed baseURI_);
    event Withdraw(address indexed to, uint256 indexed amount);

    string internal _name;
    string internal _symbol;
    string internal _baseURI;
    uint16 internal _mintedSupply;
    uint16 public maxSupply;
    uint16 public totalSupply;
    uint64 public immutable price;
    bool mintActive;
    bool uriLocked;

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint16 maxSupply_,
        uint64 price_
    ) {
        _initializeOwner(owner_);
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        maxSupply = maxSupply_;
        price = price_;
        emit UpdateBaseURI(baseURI_);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function contractURI() external view returns (string memory) {
        return _baseURI.concat("contract.json");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) return "";
        else return _baseURI.concat(tokenId.toString());
    }

    function __mint(address to, uint16 amount) internal {
        uint16 currentSupply = _mintedSupply;
        if (!mintActive) revert Locked();
        if (msg.value < price) revert InsufficientPayment();
        if (currentSupply + amount > maxSupply) revert SupplyCapReached();
        for (uint16 i; i < amount;) {
            unchecked {
                _mint(to, ++currentSupply);
                ++i;
            }
        }
        unchecked {
            totalSupply += amount;
            _mintedSupply += amount;
        }
    }

    function mint() public payable {
        uint64 cost = price;
        uint16 amount = uint16(msg.value / cost);
        uint256 spend = cost * amount;
        __mint(msg.sender, amount);
        if (msg.value > spend) {
            (bool success,) = payable(msg.sender).call{value: msg.value - spend}("");
            if (!success) revert TransferFailed();
        }
    }

    function mint(uint16 amount) external payable {
        __mint(msg.sender, amount);
    }

    function mint(address to, uint16 amount) external payable {
        __mint(to, amount);
    }

    function burn(uint256 tokenId) external {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert Unauthorized();
        _burn(tokenId);
        unchecked {
            totalSupply -= 1;
        }
    }

    function openMint() external onlyOwner {
        mintActive = true;
        emit MintOpened();
    }

    function closeMint() external onlyOwner {
        mintActive = false;
        emit MintClosed();

        uint16 supply = totalSupply;
        if (supply < maxSupply) {
            maxSupply = supply;
            emit SupplyUpdate(supply);
        }
    }

    function updateBaseURI(string memory baseURI_) external onlyOwner {
        if (uriLocked) revert Locked();
        _baseURI = baseURI_;
        emit UpdateBaseURI(baseURI_);
    }

    function lockURI() public onlyOwner {
        uriLocked = true;
        emit URILocked();
    }

    function withdrawETH(address to) external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = payable(to).call{value: amount}("");
        if (!success) revert TransferFailed();
        emit Withdraw(to, amount);
    }

    function renounceOwnership() public payable override onlyOwner {
        if (!uriLocked) lockURI();
        super.renounceOwnership();
    }

    receive() external payable {
        mint();
    }

    fallback() external payable {
        mint();
    }
}
