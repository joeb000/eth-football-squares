require('module-alias/register')

const utils = require("@utils");
const fs = require("fs");

let deployAccount = utils.ethersAccount(0)

const main = async () => {
    console.log('deploying contracts...')

    const exampleContract = await deployContractAndWriteToFile('Football', deployAccount, [])
    console.log("contract deployed at address: " + exampleContract.address)


    const tokenContract = await deployContractAndWriteToFile('FootballToken', deployAccount, ['FBL','Football Token', 2])
    console.log("token contract deployed at address: " + tokenContract.address)
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