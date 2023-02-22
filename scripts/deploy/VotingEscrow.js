// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployContract, contractAt, sendTxn } = require("../shared/helpers");
require("dotenv").config();

async function main() {
    // await deployContract("VotingEscrow",
    //   [
    //     process.env.THE,
    //     process.env.VE_ART_PROXY
    //   ]);

    const contract = await contractAt("VotingEscrow", process.env.VOTINGESCROW);
    await sendTxn(contract.isApprovedOrOwner("", 1), "VoterV2_1.isApprovedOrOwner");
    await sendTxn(contract.setVoter(process.env.VoterV3), "VoterV2_1.setVoter");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
