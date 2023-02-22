// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract } = require("../../shared/helpers");

async function main() {
    const airdropClaim = "" // AirdropClaimCusNFT.js
    await deployContract("MerkleTreeCusNFT", [ airdropClaim ]);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
