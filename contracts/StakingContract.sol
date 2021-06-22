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
    @dev Get the returned `amount` to exchange.
    @notice This function is for calling the `amountout` in swap.
  **/
  function _getReturn(
    IERC20 _fromToken,
    IERC20 _destToken,
    address _pair,
    uint256 amountIn
  ) internal view returns (uint256) {
    uint256 reserveIn = _fromToken.balanceOf(address(_pair));
    uint256 reserveOut = _destToken.balanceOf(address(_pair));

    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    return (denominator == 0) ? 0 : numerator.div(denominator);
  }

  /** 
    
  **/
  function getPairAndBalance(address _tokenFrom, address _tokenTo) public payable {
    IWeth(WETH).deposit{value: msg.value.div(2)}();
    IWeth(WETH).transfer(_getAddressPair(_tokenFrom, _tokenTo), msg.value.div(2));

    uint256 amount0Out = _tokenFrom == IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).token1() ? _getReturn(
      IERC20(_tokenFrom), 
      IERC20(_tokenTo), 
      _getAddressPair(_tokenFrom, _tokenTo), 
      msg.value.div(2)
    ) : 0;
    uint256 amount1Out = _tokenFrom == IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).token0() ? _getReturn(
      IERC20(_tokenFrom), 
      IERC20(_tokenTo), 
      _getAddressPair(_tokenFrom, _tokenTo), 
      msg.value.div(2)
    ) : 0;

    IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).swap(
      amount0Out,
      amount1Out,
      address(this), 
      ""
    );
    IERC20(_tokenFrom).safeTransfer(
      _getAddressPair(_tokenFrom, _tokenTo),
      IERC20(_tokenFrom).balanceOf(address(this))
    );
    IERC20(_tokenTo).safeTransfer(
      _getAddressPair(_tokenFrom, _tokenTo),
      IERC20(_tokenTo).balanceOf(address(this))
    );
    IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).mint(address(this));
  }
}