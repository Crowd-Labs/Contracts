import { HardhatUserConfig } from "hardhat/types";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from 'dotenv'
import 'hardhat-deploy'

dotenv.config()

const deployKey = process.env.DEPLOY_PRIVATE_KEY || '0x' + '11'.repeat(32)
const goveKey = process.env.GOVE_PRIVATE_KEY || '0x' + '11'.repeat(32)
const treasuryKey = process.env.TREASURY_PRIVATE_KEY || '0x' + '11'.repeat(32)
const BLOCK_EXPLORER_KEY = process.env.BLOCK_EXPLORER_KEY || '';

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.18',
        settings: {
          optimizer: {
            enabled: true,
            runs: 20,
            details: {
              yul: true,
            },
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      gas: 16000000,
    },
    blast_testnet: {
      chainId: 168587773,
      url: process.env.TEST_RPC_URL || '',
      accounts: [deployKey, goveKey, treasuryKey],
    },
    blast: {
      chainId: 81457,
      url: process.env.MAIN_RPC_URL || '',
      accounts: [deployKey, goveKey, treasuryKey],
    },
  },
  etherscan: {
    apiKey: {
      blast: BLOCK_EXPLORER_KEY,
    },
    customChains: [
      {
        network: "blast",
        chainId: 81457,
        urls: {
          apiURL: "https://api.routescan.io/v2/network/mainnet/evm/81457/etherscan",
          browserURL: "https://blastexplorer.io"
        }
      }
    ]
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    governance: {
      default: 1,
    },
    treasury: {
      default: 2,
    }
  },
};

export default config;