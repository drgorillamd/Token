const Migrations = artifacts.require("Migrations");
const iBNB = artifacts.require("iBNB");

module.exports = function(deployer, network) {
  if (network="testnet") {
    deployer.deploy(iBNB, "0xD99D1c33F9fC3444f8101754aBC46c52416550D1");
  }
  else if (network="bsc") {
    deployer.deploy(iBNB, "0x10ED43C718714eb63d5aA57B78B54704E256024E");
  }
};
