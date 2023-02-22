// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, upgradeContractProxy, sendTxn, contractAt } = require("../shared/helpers");

async function main() {
    //deploy contract
    // await deployProxyContract("VoterV3",
    //   [
    //     process.env.VOTINGESCROW,
    //     process.env.PAIRFACTORYUPGRADEABLE,
    //     process.env.GAUGEFACTORYV2,
    //     process.env.BRIBEFACTORYV2,
    //   ]);

    //upgrade contract
    const contract = await contractAt("VoterV3", process.env.VoterV3);
    // await sendTxn(contract.whitelist(process.env.USDT), "VoterV3.whitelist");
    await sendTxn(contract.setMinter(process.env.PUBLICKEY), "VoterV3.setMinter");
    // await sendTxn(contract.vote(1, ["", ""], [70, 30], { gasLimit: 6000000 }), "VoterV3.whitelist");
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
