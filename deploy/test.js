require('module-alias/register')

const utils = require('@utils');
const ethers = require('ethers')

const account = utils.ethersAccount(0)
const redeemer = utils.ethersAccount(1)

const contract = utils.getDeployedContract('Football')

const main = async () => {
    const football = contract.connect(account)

    //await football.createGame("joe");
    let tx = await football.resetGame();
    await tx.wait()

    let col = await football.getGameColumns(account.address);
    console.log(col)
    let rows = await football.getGameRows(account.address);
    console.log(rows)
    // await football.pickSquare(0,5);
    // await football.pickSquare(5,5);


    //let square = await football.getSquare(2,0);
    //console.log(square)
}

const createAndSignCertificates = async (n) => {
}
main();