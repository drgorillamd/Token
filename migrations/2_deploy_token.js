const Migrations = artifacts.require("Migrations");
const iBNB = artifacts.require("iBNB");

module.exports = function(deployer) {
  deployer.deploy(iBNB);
};
