const { ethers, upgrades } = require('hardhat');
const assert = require('assert');

/*
  Describing the tests, for the staking
  contract.
*/
describe('StakingContract: Testing Staking Contract', () => {
  let stakingC;
  let iWETH;

  let owner;
  let account2;

  const WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
  const DAI = '0x6b175474e89094c44da98b954eedeac495271d0f';
  const USDT = '0xdAC17F958D2ee523a2206206994597C13D831ec7';

  before(async () => {
    [owner, account2] = await ethers.getSigners();

    const StakingContract = await ethers.getContractFactory('StakingContract');
    stakingC = await upgrades.deployProxy(StakingContract, [owner.address]);
    await stakingC.deployed();

    iWETH = await ethers.getContractAt('IWeth', WETH);
  });

  it('should deploy the contract with the proxy', async () => {
    assert.ok(stakingC.address);
  });

  it('should create the stake', async () => {
    await stakingC
      .connect(account2)
      .createStake(
        WETH,
        DAI,
        0,
        '0x0000000000000000000000000000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000000000000000000000000000',
        0,
        {
          value: ethers.utils.parseUnits('1', 18),
        }
      );
    assert(Number((await stakingC.stakeOf(account2.address)).toString()) > 0);
  });

  it('should sign a transaction and then approve', async () => {
    const pairV2 = await ethers.getContractAt(
      'IUniswapV2Pair',
      await stakingC._getAddressPair(WETH, DAI)
    );

    await iWETH.deposit({ value: ethers.utils.parseEther('0.5') });
    await iWETH.transfer(pairV2.address, ethers.utils.parseEther('0.5'));
    await iWETH.deposit({ value: ethers.utils.parseEther('0.5') });

    console.log(String(await iWETH.balanceOf(owner.address)));

    const amount0Out =
      WETH === (await pairV2.token1())
        ? String(
            await stakingC._getReturn(WETH, DAI, ethers.utils.parseEther('0.5'))
          )
        : 0;
    const amount1Out =
      WETH === (await pairV2.token0())
        ? String(
            await stakingC._getReturn(WETH, DAI, ethers.utils.parseEther('0.5'))
          )
        : 0;

    await pairV2.swap(amount0Out, amount1Out, owner.address, '0x');

    console.log(
      'Balance of Owner: >> ',
      String(await pairV2.balanceOf(owner.address))
    );

    // const domain = {
    //   name: 'Uniswap V2',
    //   version: '1',
    //   chainId: 1,
    //   verifyingContract: pairV2.address,
    // };

    // const types = {
    //   Permit: [
    //     {
    //       name: 'owner',
    //       type: 'address',
    //     },
    //     {
    //       name: 'spender',
    //       type: 'address',
    //     },
    //     {
    //       name: 'value',
    //       type: 'uint256',
    //     },
    //     {
    //       name: 'nonce',
    //       type: 'uint256',
    //     },
    //     {
    //       name: 'deadline',
    //       type: 'uint256',
    //     },
    //   ],
    // };

    // const deadline = Date.now() + 1;

    // const amount = (await pairV2.balanceOf(owner.address)).toString();

    // const value = {
    //   owner: owner.address,
    //   spender: stakingC.address,
    //   value: amount,
    //   nonce: Number(await pairV2.nonces(owner.address)),
    //   deadline: deadline,
    // };

    // const signature = (
    //   await owner._signTypedData(domain, types, value)
    // ).substring(2);
    // const r = '0x' + signature.substring(0, 64);
    // const s = '0x' + signature.substring(64, 128);
    // const v = parseInt(signature.substring(128, 130), 16);

    // await stakingC.createStake(WETH, DAI, v, r, s, deadline);

    // console.log(
    //   'Balance Owner: >> ',
    //   String(await pairV2.balanceOf(owner.address))
    // );
  });
});
