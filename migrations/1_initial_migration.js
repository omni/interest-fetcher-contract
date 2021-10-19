const InterestFetcher = artifacts.require("InterestFetcher");

module.exports = function (deployer) {
  deployer.deploy(InterestFetcher, '0x75Df5AF045d91108662D8080fD1FEFAd6aA0bb59', 36000);
};
