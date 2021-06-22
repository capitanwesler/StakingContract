// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IWeth.sol";
import "hardhat/console.sol";

/**
  @title StakingContract, to staking LP tokens into the contract.
  @author Guillermo Rivas (@capitanwesler).
**/

contract StakingContract is Initializable, Context {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  address constant FactoryUniswap = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
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

  /** 
    
  **/
  function getPairAndBalance(address _tokenA, address _tokenB) public payable {
    console.log("Balance of User in ETH: >> %s", _msgSender().balance);
    IERC20(_tokenB).safeTransferFrom(_msgSender(), address(this), 300 * 1e18);
    IWeth(WETH).deposit{value: msg.value}();
    console.log("Balance of User in WETH: >> %s", IWeth(WETH).balanceOf(address(this)));
    IWeth(WETH).transfer(_getAddressPair(_tokenA, _tokenB), msg.value);
    IUniswapV2Pair(_getAddressPair(_tokenA, _tokenB)).mint(address(this));
    console.log(IUniswapV2Pair(_getAddressPair(_tokenA, _tokenB)).balanceOf(address(this)));
  }
}