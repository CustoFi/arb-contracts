// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, contractAt, sendTxn } = require("../shared/helpers");

async function main() {
    const VoterV3 = await contractAt("VoterV3", process.env.VoterV3)
    let txn = await sendTxn(VoterV3.whitelist([ process.env.WFTM ], { gasLimit: 6000000 }), "VoterV3.whitelist");
    // console.log(txn);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
