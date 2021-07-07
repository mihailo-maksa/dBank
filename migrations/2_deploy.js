const Token = artifacts.require('Token')
const dBank = artifacts.require('dBank')

module.exports = async function (deployer) {
  // deploy Token
  await deployer.deploy(Token)

  // assign token into variable to get it's address
  const token = await Token.deployed()

  // pass token address for dBank contract(for future minting)
  await deployer.deploy(dBank, token.address)

  // assign dBank contract into variable to get it's address
  const dBankContract = await dBank.deployed()

  // change token's owner/minter from deployer to dBank's contract address
  await token.passMinterRole(dBankContract.address)
}
