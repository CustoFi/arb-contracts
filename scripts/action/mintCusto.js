// // scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat");
const { deployProxyContract, contractAt, sendTxn } = require("../shared/helpers");

async function main() {
    const custo = await contractAt("Custo", process.env.CUS)
    let txn = await sendTxn(custo.mint(process.env.PUBLICKEY, ethers.utils.parseUnits("100000000", 18), { gasLimit: 6000000 }), "custo.mint");
    // console.log(txn);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
