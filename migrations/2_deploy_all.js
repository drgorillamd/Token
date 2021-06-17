const Migrations = artifacts.require("Migrations");
const iBNB = artifacts.require("iBNB");
//const iBNBPresale = artifacts.require("iBNB-presale");

const BSC_mainnet_routeur = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
const BSC_test_routeur = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
const devWallet = "0x000000000000000000000000000000000000dEaD";


module.exports = function(deployer, network) {
  if (network=="testnet") {
    deployer.deploy(iBNB, BSC_test_routeur, devWallet);
    //deployer.deploy(iBNBPresale, iBNB.address, BSC_test_routeur);
  }
  else if (network=="bsc") {
    deployer.deploy(iBNB, BSC_mainnet_routeur, devWallet);
    //deployer.deploy(iBNBPresale, iBNB.address, BSC_mainnet_routeur);
  }
  else if (network=="ganache") {
    deployer.deploy(iBNB, BSC_mainnet_routeur, devWallet);
    //deployer.deploy(iBNBPresale, iBNB.address, BSC_mainnet_routeur);
    }
};
