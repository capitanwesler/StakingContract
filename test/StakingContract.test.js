const { ethers, upgrades } = require('hardhat');
const assert = require('assert');

/*
  Describing the tests, for the staking
  contract.
*/
describe('StakingContract: Testing Staking Contract', () => {
  let stakingC;
  let owner;
  const WETH = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2';
  const DAI = '0x6b175474e89094c44da98b954eedeac495271d0f';
  const USDT = '0xdAC17F958D2ee523a2206206994597C13D831ec7';

  before(async () => {
    [owner] = await ethers.getSigners();

    const StakingContract = await ethers.getContractFactory('StakingContract');
    stakingC = await upgrades.deployProxy(StakingContract, [owner.address]);
    await stakingC.deployed();
  });

  it('should deploy the contract with the proxy', async () => {
    assert.ok(stakingC.address);
  });

  it('should create the stake', async () => {
    await stakingC.createStake(WETH, DAI, {
      value: ethers.utils.parseUnits('1', 18),
    });
    assert(Number((await stakingC.stakeOf(owner.address)).toString()) > 0);
  });

  it('should sign a transaction and then approve', async () => {
    const pairV2 = await ethers.getContractAt(
      'IUniswapV2Pair',
      await stakingC._getAddressPair(WETH, DAI)
    );

    const domain = {
      name: 'Uniswap V2',
      version: '1',
      chainId: 1,
      verifyingContract: pairV2.address,
    };

    const types = {
      Permit: [
        {
          name: 'owner',
          type: 'address',
        },
        {
          name: 'spender',
          type: 'address',
        },
        {
          name: 'value',
          type: 'uint256',
        },
        {
          name: 'nonce',
          type: 'uint256',
        },
        {
          name: 'deadline',
          type: 'uint256',
        },
      ],
    };

    const deadline = Date.now() + 1;

    const amount = (await pairV2.balanceOf(owner.address)).toString();

    const value = {
      owner: owner.address,
      spender: stakingC.address,
      value: amount,
      nonce: Number(await pairV2.nonces(owner.address)),
      deadline: deadline,
    };

    const signature = (
      await owner._signTypedData(domain, types, value)
    ).substring(2);
    const r = '0x' + signature.substring(0, 64);
    const s = '0x' + signature.substring(64, 128);
    const v = parseInt(signature.substring(128, 130), 16);

    await stakingC.createStake(WETH, DAI, v, r, s, deadline);

    console.log(
      'Allowance: >> ',
      (await pairV2.allowance(owner.address, stakingC.address)).toString()
    );

    console.log(
      'Balance Conctract: >> ',
      String(await pairV2.balanceOf(stakingC.address))
    );
    console.log(
      'Balance Owner: >> ',
      String(await pairV2.balanceOf(owner.address))
    );
  });
});
