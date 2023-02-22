// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, sendTxn } = require("../shared/helpers");
require("dotenv").config();

async function main() {
    // await deployContract("Custo", []);

    const contract = await contractAt("Custo", process.env.CUS);
    await sendTxn(contract.mint("", ethers.utils.parseUnits("10000", 18)), "VoterV2_1.mint");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
