// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
* @title Staking Token (STK).
* @author Guillermo Rivas.
* @notice Implements a basic ERC20 staking token.
*/
contract StakeToken is Initializable, ERC20Upgradeable {
  function initialize(string memory _name, string memory _symbol) public initializer {
    __ERC20_init(_name, _symbol);
  }

  /** 
    @dev Adding the mint function for the token to mint.
  **/
  function mint(address _to, uint256 _amount) public {
    _mint(_to, _amount);
  }
}