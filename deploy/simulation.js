require('module-alias/register')

const utils = require('@utils');
const ethers = require('ethers')

const squaresContract = utils.getDeployedContract('Football')
const tokenContract = utils.getDeployedContract('FootballToken')
const mainAccount = utils.ethersAccount(0)

const main = async () => {
    await mintToken();
    //await initializeToken();
    let gameId = await initializeGame()
    //console.log(gameId)
    //let gameId = '0xf011d6c8c4111bd1779716f10b9183ab985375c1d664dd0a9f09eaa9f82c6f7d'
    await chooseSquare(gameId, 0,3)
    //await chooseSquares(gameId)
    //await printSquares(gameId)
    //await shuffleAndSetWinner(gameId)
    //await printBalances()
    //await claimReward(gameId, utils.ethersAccount(2))
    // await collectFee()
    // await printBalances()

    let a1 = await squaresContract.getSquare(gameId, 0, 3)
    let a2 =  await squaresContract.getSquareValue(gameId, 3)

    console.log(a1)
    console.log(a2)
}

const mintToken = async () => {
    let contract = tokenContract.connect(mainAccount);
    let beforeBal = await contract.balanceOf(mainAccount.address);
    await contract.mint(mainAccount.address, 10000)
    await  utils.callContract(tokenContract,mainAccount,'approve', [squaresContract.address, 100000])

    let afterBal = await contract.balanceOf(mainAccount.address);
    console.log("Before: " + beforeBal + " after: " + afterBal)
}
const initializeToken = async () => {
    let contract = tokenContract.connect(mainAccount);

    let beforeBal = await contract.balanceOf(mainAccount.address);

    await contract.mint(mainAccount.address, 1000)

    for (let i = 0; i < 10; i++) {
        const account = utils.ethersAccount(i);
        const addr = account.address
        await contract.mint(addr, 1000)
        await  utils.callContract(tokenContract,account,'approve', [squaresContract.address, 100000])
    }

    let afterBal = await contract.balanceOf(mainAccount.address);
    console.log("Before: " + beforeBal + " after: " + afterBal)
    let bal = await contract.balanceOf(utils.ethersAccount(9).address);
    console.log("9bal: " + bal)
}

const initializeGame = async () => {
    let nonce = await squaresContract.nonce(mainAccount.address);
    console.log("nonce", nonce)
    await utils.callContract(squaresContract,mainAccount,'createGame', [tokenContract.address, 10, "The best game"])
    let gameID = await squaresContract.getGameId(mainAccount.address, nonce);
    console.log("Game ID: " + gameID)

    let game = await squaresContract.games(gameID);
    console.log(game)
    return gameID
}

const chooseSquares = async (gameId) => {
    for (let i = 0; i < 10; i++) {
        const account = utils.ethersAccount(i);
        for (let j = 0; j < 10; j++) {
            await utils.callContract(squaresContract,account,'pickSquare', [gameId, j,i])
        }
    }
}
const chooseSquare = async (gameId, col, row) => {

    await utils.callContract(squaresContract,mainAccount,'pickSquare', [gameId, col, row])

}

const printSquares = async (gameId) => {
    let rows = []
    for (let i = 0; i < 10; i++) {
        let row = []
        for (let j = 0; j < 10; j++) {
           row.push(await squaresContract.getSquare(gameId,j,i));
        }
        rows.push(row)
    }
    console.log(rows)
}

const shuffleAndSetWinner = async (gameId) => {
    //await utils.callContract(squaresContract,mainAccount,'shuffleGame', [gameId])

    let cols = await squaresContract.getGameColumns(gameId)
    let rows = await squaresContract.getGameRows(gameId)

    console.log("columns: " + cols)
    console.log("rows: " + rows)

    await utils.callContract(squaresContract,mainAccount,'setWinner', [gameId, 3,2])

    let winner = await squaresContract.getSquare(gameId, 3,2)

    console.log("Winner: " + winner)
}

const claimReward = async (gameId, account) => {
    await utils.callContract(squaresContract, account,'claimReward', [gameId])
}

const collectFee = async () => {
    await utils.callContract(squaresContract, mainAccount,'collectFee', [tokenContract.address, mainAccount.address])

}

const printBalances = async () => {
    for (let i = 0; i < 10; i++) {
        const account = utils.ethersAccount(i);
        const addr = account.address
        //await contract.mint(addr, 1000)
        let acctBal = await tokenContract.balanceOf(addr);
        console.log(addr+": " + acctBal)
    }
}
main();