const LiquidDemocracy = artifacts.require("LiquidDemocracy")
const AddressArray = artifacts.require("AddressArray");
const LinkCutTree = artifacts.require("LinkCutTree");
async function performMigration(deployer, network, accounts) {
    await AddressArray.deployed();
    await LinkCutTree.deployed();
    await deployer.link(AddressArray, LiquidDemocracy);
    await deployer.link(LinkCutTree, LiquidDemocracy);
    await deployer.deploy(LiquidDemocracy);
}
module.exports = function(deployer, network, accounts){
deployer
    .then(function() {
      return performMigration(deployer, network, accounts)
    })
    .catch(error => {
      console.log(error)
      process.exit(1)
    })
};
