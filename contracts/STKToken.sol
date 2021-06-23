// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title Staking Token (STK).
* @author Guillermo Rivas.
* @notice Implements a basic ERC20 staking token.
*/
contract StakingToken is ERC20, Ownable {
   constructor() ERC20("StakingToken", "STK") {}
}