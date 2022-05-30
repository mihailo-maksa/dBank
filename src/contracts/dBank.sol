// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Token.sol";

contract dBank {
  Token private token;

  mapping(address => uint) public depositStart;
  mapping(address => uint) public etherBalanceOf; // ether balance of user in dBank
  mapping(address => uint) public collateralEther; // user's ether that's used as collateral
  
  mapping(address => bool) public isDeposited;
  mapping(address => bool) public isBorrowed;

  event Deposit(address indexed user, uint etherAmount, uint timeStart);
  event Withdraw(address indexed user, uint etherAmount, uint tokenAmount, uint depositTime); // depositTime = hodl time
  event Borrow(address indexed user, uint collateralEtherAmount, uint borrowedTokenAmount);
  event Repay(address indexed user, uint fee);

  constructor (Token _token) public {
    token = _token;
  }

  function deposit() public payable {
    require(isDeposited[msg.sender] == false, "Deposit is already active.");
    require(msg.value >= 1e16, "You must deposit 0.01 ETH or more.");

    etherBalanceOf[msg.sender] = etherBalanceOf[msg.sender] + msg.value;
    depositStart[msg.sender] = depositStart[msg.sender] + block.timestamp;
    
    isDeposited[msg.sender] = true;
    emit Deposit(msg.sender, msg.value, block.timestamp);
  }

  function withdraw() public {
    require(isDeposited[msg.sender] == true, "No funds available to withdraw.");
    // assign msg.sender ether deposit balance to variable 
    uint userBalance = etherBalanceOf[msg.sender]; // for event emission

    // check user's hodl time
    uint depositTime = block.timestamp - depositStart[msg.sender]; // in seconds

    // calc interest per second
    // calc accrued interest 
    // 31668017 = 1e15 / 31577600 (10% APY for min. deposit of 0.01 ETH = 10% of 0.01 ETH / number of seconds in 365.25 days, i.e. one year)
    uint interestPerSecond = 31668017 * (userBalance / 1e16); // 1e16 = deposit minimum of 0.01 ETH
    uint accruedInterest = interestPerSecond * depositTime;

    // send eth to user
    msg.sender.transfer(userBalance);

    // mint DBT and send it to user
    token.mint(msg.sender, accruedInterest);

    // reset depositer data
    etherBalanceOf[msg.sender] = 0;
    depositStart[msg.sender] = 0;
    isDeposited[msg.sender] = false;

    // emit event
    emit Withdraw(msg.sender, userBalance, accruedInterest, depositTime);
  }

   function borrow() public payable {
     require(msg.value>=1e16, 'Error, collateral must be >= 0.01 ETH');
     require(isBorrowed[msg.sender] == false, 'Error, loan already taken');

     //this Ether will be locked till user payOff the loan
     collateralEther[msg.sender] = collateralEther[msg.sender] + msg.value;

     // calc tokens amount to mint, 50% of msg.value (can be customized later to allow for the arbitrary borrow amounts)
     uint tokensToMint = collateralEther[msg.sender] / 2;

     // mint&send tokens to user
     token.mint(msg.sender, tokensToMint);

     // activate borrower's loan status
     isBorrowed[msg.sender] = true;

     emit Borrow(msg.sender, collateralEther[msg.sender], tokensToMint);
   }

   function repay() public {
     require(isBorrowed[msg.sender] == true, 'Error, loan not active');
     
     token.approve(address(this), collateralEther[msg.sender]/2); // approve token spending by the contract
     require(token.transferFrom(msg.sender, address(this), collateralEther[msg.sender]/2), "Error, can't receive tokens"); //must approve dBank 1st

     uint fee = collateralEther[msg.sender]/10; //calc 10% fee

     // send user's collateral minus fee
     msg.sender.transfer(collateralEther[msg.sender]-fee);

     // reset borrower's data
     collateralEther[msg.sender] = 0;
     isBorrowed[msg.sender] = false;

     emit Repay(msg.sender, fee);
   }
}
