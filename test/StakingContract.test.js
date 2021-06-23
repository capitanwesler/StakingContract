const { ethers, upgrades } = require('hardhat');

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
    console.log('StakingContract deployed to:', stakingC.address);
  });

  it('should get the quote of the tokens', async () => {
    await stakingC.getQuote(WETH, USDT, {
      value: ethers.utils.parseEther('1'),
    });
  });

  // it('should show the balance of the signer in pair', async () => {
  //   await stakingC.getPairAndBalance(WETH, DAI, {
  //     value: ethers.utils.parseUnits('1', 18),
  //   });
  // });
});
