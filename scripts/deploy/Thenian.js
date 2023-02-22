// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, sendTxn } = require("../shared/helpers");
const { bigNumberify } = require("../shared/utilities");
require("dotenv").config();

async function main() {
    // await deployContract("Custodian", [3000, ethers.utils.parseUnits("25", 17), 1669993200]);

    //Mint theNFT
    const contract = await contractAt("Custodian", process.env.CUSTODIAN);
    await sendTxn(contract.reserveNFTs("", 5), "VoterV3.mint");
    await sendTxn(contract.reserveNFTs("", 15), "VoterV3.mint");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
