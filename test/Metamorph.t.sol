// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Metamorph} from "../src/Metamorph.sol";

contract MetamorphTest is Test {
    Metamorph public nft;

    function setUp() public {
        nft = new Metamorph(address(this), "Metamorph", "MMORPH", "https://metamorph.xyz", 2000, 0.1 ether);
    }

    function testMint() public {
        nft.openMint();
        nft.mint{value: 0.2 ether}();
        (bool success,) = payable(address(nft)).call{value: 0.3 ether}("");
        if (!success) revert();
        nft.closeMint();
        nft.maxSupply();
    }
}
