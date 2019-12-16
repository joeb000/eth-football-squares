const newRandom = (n) => Math.floor(Math.random()*n)
let endArray = []
let struckPositions = [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]
let r
for (let i = 10; i > 0; i--) {
    // new keccak in solidity
    r = newRandom(2000000)
    let nextPos = r%i;
    for (let j = 0; j <= nextPos; j++) {
        if (struckPositions[j]!=-1) {
            nextPos++;
        }
    }
    struckPositions[nextPos] = nextPos
    endArray.push(nextPos)
}
console.log(endArray)