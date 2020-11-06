const AddressArray = artifacts.require("AddressArray");
const LinkCutTree = artifacts.require("LinkCutTree");
module.exports = function(deployer) {
    deployer.deploy(AddressArray);
    deployer.deploy(LinkCutTree);
};
