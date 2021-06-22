// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "hardhat/console.sol";

/**
  @title StakingContract, to staking LP tokens into the contract.
  @author Guillermo Rivas (@capitanwesler).
**/

contract StakingContract is Initializable, Context {
  using SafeMath for uint256;
  address constant FactoryUniswap = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address public owner;

  function initialize(address _owner) public initializer {
    owner = _owner;
    console.log("Initializing the contract...");
  }

  /** 
    @dev Gets the pairs address between two tokens.
    @notice This calls the function of `IUniswapFactory`.
    @return The address of the pair in the `factory`.
  **/
  function _getAddressPair(address _tokenA, address _tokenB) internal view returns(address) {
    return IUniswapV2Factory(FactoryUniswap).getPair(_tokenA, _tokenB);
  }
}