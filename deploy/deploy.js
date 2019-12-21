require('module-alias/register')

const utils = require("@utils");
const fs = require("fs");
const ethers = require('ethers')

let deployAccount = utils.ethersAccount(0)

const main = async () => {
    console.log('deploying contracts...')
  await deployFootball()

  let tokenAddress = "0xa7d5A6834054941e82E7229Eff7151A6c6e7F0d1"
  await deployFaucet(tokenAddress)
}

const deployFootball = async () => {
  const fbContract = await deployContractAndWriteToFile('Football', deployAccount, [])
  console.log("contract deployed at address: " + fbContract.address)
  return fbContract
}

const deployToken = async () => {
  const tokenContract = await deployContractAndWriteToFile('FootballToken', deployAccount, ['FBL','Football Token', 2])
  console.log("token contract deployed at address: " + tokenContract.address)
  return tokenContract
}

const deployFaucet = async (tokenAddress) => {
  const faucetContract = await deployContractAndWriteToFile('Faucet', deployAccount, [])
  console.log("Faucet contract deployed at address: " + faucetContract.address)
  let f = faucetContract.connect(deployAccount)
  let tx = await f.set(tokenAddress, 1000)
  console.log(tx)
  const contract = utils.getDeployedContract('FootballToken')
  const token = contract.connect(deployAccount)
  let tx2 = await token.mint(faucetContract.address, ethers.utils.bigNumberify('10000000000000000000000000000')) //10000000000000000000000000000
}

const deployContractAndWriteToFile = async (contractName, deployerWallet, params) => {
    //check if output dir exists, if not create it
    const outputDirRoot = `./build/deployed`;
    console.log(fs.existsSync('./build'))
    if (!fs.existsSync(outputDirRoot)) {
      fs.mkdirSync(outputDirRoot);
    }
  
    const outputDir = `${outputDirRoot}/${utils.networkName}`
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir);
    }
  
    let contract = require(`@contracts/${contractName}.json`)
  
    //console.log(contract)
  
    //console.log(contract.abi)
    let deployedContract = await utils.deployContract(
      contract.abi,
      contract.bytecode,
      deployerWallet,
      params
    );
    let networks = {}
    networks[utils.networkID] = {
      address: deployedContract.address,
      transactionHash: deployedContract.deployTransaction.hash,
    }
  
    let truffleLike = {
      contractName,
      name: contractName,
      abi: contract.abi,
      bytecode: contract.bytecode,
      networks
    }
    utils.writeToFile(`${outputDir}/${contractName}.json`, truffleLike)
  
    return deployedContract
  }

main()