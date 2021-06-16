const Migrations = artifacts.require("Migrations");

module.exports = function (deployer, network) {
  if (network=="testnet" || network=="ganache") {
    deployer.deploy(Migrations);
  }
  else {
    
  }

};
