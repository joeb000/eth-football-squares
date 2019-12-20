require('module-alias/register')

const utils = require('@utils');
const ethers = require('ethers')

const account = utils.ethersAccount(0)
const redeemer = utils.ethersAccount(1)

const contract = utils.getDeployedContract('FootballToken')

const main = async () => {

    let faucetAddress = "0x34319CE659D0642a7C076d0115E0719704E56568"
    const token = contract.connect(account)
    await token.mint(faucetAddress, ethers.utils.bigNumberify('10000000000000000000000000000'))


}

const createAndSignCertificates = async (n) => {
}
main();