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
    blast: {
      chainId: 168587773,
      url: process.env.TEST_RPC_URL || '',
      accounts: [deployKey, goveKey, treasuryKey],
      gas: 3_000_000,
    },
  },
  etherscan: {
    apiKey: BLOCK_EXPLORER_KEY,
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