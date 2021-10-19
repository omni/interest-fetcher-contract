require('dotenv').config()
const HDWalletProvider = require("@truffle/hdwallet-provider")

const privateKey = process.env.DEPLOYMENT_ACCOUNT_PRIVATE_KEY

module.exports = {
  networks: {
    xdai: {
      provider: () => new HDWalletProvider(privateKey, 'https://dai.poa.network'),
      network_id: 100,
      gasPrice: '1000000000',
      skipDryRun: true,
    }
  },
  compilers: {
    solc: {
      version: "0.8.9",
      settings: {
        optimizer: {
          enabled: true,
          runs: 5000000,
        },
        evmVersion: "berlin",
      },
    },
  },
};
