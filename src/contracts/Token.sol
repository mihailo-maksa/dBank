// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
  address public minter;

  event MinterChanged(address indexed from, address indexed to);

  constructor() public payable ERC20("dBank Token", "DBT") {
    minter = msg.sender;
  }

  function passMinterRole(address dBankMinter) public returns(bool) {
    require(msg.sender == minter, "Only owner can pass the minter role.");
    minter = dBankMinter;

    emit MinterChanged(msg.sender, dBankMinter);
    return true;
  }

  function mint(address account, uint amount) public {
    require(msg.sender == minter, "Only person with a minter role can mint new tokens.");
    _mint(account, amount);
  }
}
