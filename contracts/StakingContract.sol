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

  /**
    @notice To know who is a stakeholder.
  **/
  address[] internal stakeholders;

  /**
    @notice The stakes for each stakeholder.
  **/
  mapping(address => uint256) internal stakes;

  /**
    @notice The owner of the contract.
  **/
  address public owner;

  
  function initialize(address _owner) public initializer {
    owner = _owner;
  }

  /** 
    @dev Gets the pairs address between two tokens.
    @notice This calls the function of `IUniswapFactory`.
    @return The address of the pair in the `factory`.
  **/
  function _getAddressPair(address _tokenA, address _tokenB) public view returns(address) {
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
  ) public view returns (uint256) {
    (uint256 reserveA, uint256 reserveB) = _getReserves(_fromToken, _destToken);
    return _getAmountOut(amountIn, reserveA, reserveB);
  }

  function _swap(address _tokenFrom, address _tokenTo, uint256 _amountIn, address _address) internal {
    /*
      We deposit first msg.value divided by two
      to make the swap to the specific token.
    */
    IWeth(WETH).deposit{value: _amountIn.div(2)}();
    IWeth(WETH).transfer(_getAddressPair(_tokenFrom, _tokenTo), _amountIn.div(2));

    /*
      After that we deposit the ETH into WETH,
      to mint after and get the LP Tokens.
    */
    IWeth(WETH).deposit{value: _amountIn.div(2)}();

    uint256 amount0Out = _tokenFrom == IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).token1() ? _getReturn(
      _tokenFrom, 
      _tokenTo, 
      _amountIn.div(2)
    ) : 0;
    uint256 amount1Out = _tokenFrom == IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).token0() ? _getReturn(
      _tokenFrom, 
      _tokenTo, 
      _amountIn.div(2)
    ) : 0;

    IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).swap(
      amount0Out,
      amount1Out,
      _address, 
      ""
    );

    IERC20(_tokenFrom).safeTransfer(
      _getAddressPair(_tokenFrom, _tokenTo),
      IERC20(_tokenFrom).balanceOf(_address)
    );
    IERC20(_tokenTo).safeTransfer(
      _getAddressPair(_tokenFrom, _tokenTo),
      IERC20(_tokenTo).balanceOf(_address)
    );
  }

  /**
    @notice A method to check if an address is a stakeholder.
    @param _address The address to verify.
    @return bool, uint256 Whether the address is a stakeholder,
    and if so its position in the stakeholders array.
  **/
  function isStakeholder(address _address)
    public
    view
    returns(bool, uint256)
  {
      for (uint256 i = 0; i < stakeholders.length; i++){
        if (_address == stakeholders[i]) {
          return (true, i);
        }
      }
      return (false, 0);
  }

  /**
    @notice A method to add a stakeholder.
    @param _stakeholder The stakeholder to add.
  **/
  function addStakeholder(address _stakeholder)
    public
  {
    (bool _isStakeholder, ) = isStakeholder(_stakeholder);
    require(!_isStakeholder, "addStakeHolder: ALREADY_A_HOLDER");
    stakeholders.push(_stakeholder);
  }

  /**
    @notice A method to remove a stakeholder.
    @param _stakeholder The stakeholder to remove.
  **/
  function removeStakeholder(address _stakeholder)
    public
  {
    (bool _isStakeholder, uint256 _index) = isStakeholder(_stakeholder);
    require(_isStakeholder, "removeStakeholder: NOT_A_HOLDER");
    stakeholders[_index] = stakeholders[stakeholders.length - 1];
    stakeholders.pop();
  }

  /**
    @notice A method to retrieve the stake for a stakeholder.
    @param _stakeholder The stakeholder to retrieve the stake for.
    @return uint256 The amount in WEI staked.
  **/
  function stakeOf(address _stakeholder)
    public
    view
    returns(uint256)
  {
    return stakes[_stakeholder];
  }

  /** 
    @dev This function should claim the stake in the contract.
  **/
  function claimStake(address _tokenFrom, address _tokenTo) public { 
    require(stakes[_msgSender()] > 0, "claimStake: NO_STAKE_TO_CLAIM");
    IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).transfer(
      _msgSender(), 
      stakes[_msgSender()]
    );
    removeStakeholder(_msgSender());
    delete stakes[_msgSender()];
  }

  /** 
    @notice A method to create a stake.
    @dev The use need to send the ether and be added as a stake holder.
  **/
  function createStake(
      address _tokenFrom, 
      address _tokenTo,  
      uint8 v, 
      bytes32 r, 
      bytes32 s,
      uint256 deadline
    ) public payable {
    require(_tokenFrom != address(0) && _tokenTo != address(0), "createStake: ZERO_ADDRESS");
    require(stakes[_msgSender()] == 0, "createStake: ALREADY_A_HOLDER");

    if (IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).balanceOf(_msgSender()) == 0) {
      
      _swap(_tokenFrom, _tokenTo, msg.value, address(this));

      uint256 initialBalance = IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).balanceOf(address(this));
      IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).mint(address(this));
      
      /*
        Calculate how much is going to be
        stake in this holder.
      */

      if (initialBalance > 0) {
        addStakeholder(_msgSender());
        stakes[_msgSender()] = IUniswapV2Pair(
          _getAddressPair(_tokenFrom, _tokenTo)
        ).balanceOf(address(this)).sub(initialBalance);
      } else {
        addStakeholder(_msgSender());
        stakes[_msgSender()] = IUniswapV2Pair(
          _getAddressPair(_tokenFrom, _tokenTo)
        ).balanceOf(address(this));
      }
    } else {

      /*
        To stake the tokens, we first need
        to approve this contract to spend the
        pool tokens.
      */

      IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).permit(
        _msgSender(),
        address(this), 
        IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).balanceOf(_msgSender()),
        deadline,
        v,
        r,
        s
      );

      /*
        Transfering the tokens from the user,
        to the contract.
      */

      IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).transferFrom(
        _msgSender(),
        address(this),
        IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).balanceOf(_msgSender())
      );

      /*
        The initial balance of the contract
        plus the balance of the user who has
        the LP tokens.
      */
      
      uint256 addedBalance = IUniswapV2Pair(
        _getAddressPair(_tokenFrom, _tokenTo)
      ).balanceOf(
        _msgSender()
      ).add(IUniswapV2Pair(_getAddressPair(_tokenFrom, _tokenTo)).balanceOf(address(this)));

      /*
        Calculate how much is going to be
        stake in this holder.
      */

      addStakeholder(_msgSender());
      stakes[_msgSender()] = addedBalance.sub(IUniswapV2Pair(
        _getAddressPair(_tokenFrom, _tokenTo)
      ).balanceOf(address(this)));
    }
  }
}