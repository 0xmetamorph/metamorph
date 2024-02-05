// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {Metamorph} from "../src/Metamorph.sol";

contract TestnetScript is Script {
    string internal SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    uint256 internal sepoliaFork;

    Metamorph internal nft;

    function setUp() public {
        sepoliaFork = vm.createFork(SEPOLIA_RPC_URL);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.selectFork(sepoliaFork);
        vm.startBroadcast(deployerPrivateKey);
        nft = new Metamorph(
            deployer, // Contract owner
            "Metamorph", // Name
            "MMORPH", // Symbol
            "ipfs://CID/", // Metadata IPFS link, MUST END WITH A FORWARD SLASH '/'
            2000, // Max supply
            0.1 ether // Price
        );
        vm.stopBroadcast();
    }
}
