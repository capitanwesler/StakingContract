// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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
    @dev Sorts the token to see if either equal, or not.
    @notice This is to be called in the _getReserves for the pair.
  **/
  function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
      require(tokenA != tokenB, '_sortTokens: IDENTICAL_ADDRESSES');
      (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
      require(token0 != address(0), '_sortTokens: ZERO_ADDRESS');
  }

  /**
    @dev Get the reserves of the `pair`.
    @notice The reserves of the two tokens in the pair `reserveA`, `reserveB`.
  **/
  function _getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
      (address token0,) = _sortTokens(tokenA, tokenB);
      (uint reserve0, uint reserve1,) = IUniswapV2Pair(_getAddressPair(tokenA, tokenB)).getReserves();
      (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  /**
    @dev Get the exact amountOut for the `amountIn` minus fees.
  **/
  function _getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
      require(amountIn > 0, '_getAmountOut: INSUFFICIENT_INPUT_AMOUNT');
      require(reserveIn > 0 && reserveOut > 0, '_getAmountOut: INSUFFICIENT_LIQUIDITY');
      uint amountInWithFee = amountIn.mul(997);
      uint numerator = amountInWithFee.mul(reserveOut);
      uint denominator = reserveIn.mul(1000).add(amountInWithFee);
      amountOut = numerator / denominator;
  }

  /**
    @dev Get the returned `amount` to exchange.
    @notice This function is for calling the `amountout` in swap.
  **/
  function _getReturn(
    address _fromToken,
    address _destToken,
    uint256 amountIn
  ) internal view returns (uint256) {
    (uint256 reserveA, uint256 reserveB) = _getReserves(_fromToken, _destToken);
    return _getAmountOut(amountIn, reserveA, reserveB);
  }

  /** 
    
  **/
  function getPairAndBalance(address _tokenFrom, address _tokenTo) public payable {
    require()
    
    /*
      We deposit first msg.value divided by two
      to make the swap to the specific token.
    */
    IWeth(WETH).deposit{value: msg.value.div(2)}();
    IWeth(WETH).transfer(_getAddressPair(_tokenFrom, _tokenTo), msg.value.div(2));


    IWeth(WETH).deposit{value: msg.value.div(2)}();

    uint256 amount0Out = _tokenFrom == IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).token1() ? _getReturn(
      _tokenFrom, 
      _tokenTo, 
      msg.value.div(2)
    ) : 0;
    uint256 amount1Out = _tokenFrom == IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).token0() ? _getReturn(
      _tokenFrom, 
      _tokenTo, 
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

    console.log("LP Tokens: >> %s", IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).balanceOf(address(this)).div(1e18));
  }
}