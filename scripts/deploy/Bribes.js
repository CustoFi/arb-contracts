// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, writeTmpAddresses } = require("../shared/helpers");
require("dotenv").config();

async function main() {
    await deployContract("Bribe",
        [
            process.env.PUBLICKEY,
            process.env.VoterV3,
            process.env.BRIBEFACTORYV2,
            "custo Bribes: vAMM-BUSD/CUS",
        ]);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
