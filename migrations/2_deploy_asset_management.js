const AssetManagement = artifacts.require('./AssetManagement.sol');

module.exports = (deployer) => {
  deployer.deploy(AssetManagement);
}
