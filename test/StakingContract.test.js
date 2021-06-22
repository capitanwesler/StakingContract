const { ethers, upgrades } = require('hardhat');

const LINK = '0x514910771AF9Ca656af840dff83E8264EcF986CA';
const DAI = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const USDT = '0xdAC17F958D2ee523a2206206994597C13D831ec7';
const USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';

describe('Swapper: ETH for Tokens', () => {
  let swapper;
  let DAItoken;
  let LINKtoken;
  let owner;

  before(async () => {
    // - Getting the factories for the contracts:
    const Swapper = await ethers.getContractFactory('Swapper');

    [owner] = await ethers.getSigners();

    swapper = await Swapper.deploy(owner.address);
    await swapper.deployed();

    // DAI TOKEN
    DAItoken = await ethers.getContractAt('IERC20', DAI);

    // LINK TOKEN
    LINKtoken = await ethers.getContractAt('IERC20', LINK);
  });

  it('change ETH for multiple tokens for the first account', async () => {
    const porcents = [35 * 10, 35 * 10, 15 * 10, 15 * 10];
    const tokens = [
      '0x6B175474E89094C44Da98b954EedeAC495271d0F', // DAI Token
      '0x514910771AF9Ca656af840dff83E8264EcF986CA', // LINK Token
      '0xdAC17F958D2ee523a2206206994597C13D831ec7', // USDT Token
      '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', // USDC Token
    ];

    await swapper.swapEthForTokens(tokens, porcents, {
      value: ethers.utils.parseEther('5'),
    });
  });
});

/*
  Describing the tests, for the staking
  contract.
*/
describe('StakingContract: Testing Staking Contract', () => {
  let stakingC;
  let owner;
  const WETH = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2';
  const DAI = '0x6b175474e89094c44da98b954eedeac495271d0f';

  before(async () => {
    [owner] = await ethers.getSigners();

    const StakingContract = await ethers.getContractFactory('StakingContract');
    stakingC = await upgrades.deployProxy(StakingContract, [owner.address]);
    await stakingC.deployed();
  });

  it('should deploy the contract with the proxy', async () => {
    console.log('StakingContract deployed to:', stakingC.address);
  });

  it('should show the balance of the signer in pair', async () => {
    await stakingC.getPairAndBalance(WETH, DAI, {
      value: ethers.utils.parseUnits('1', 18),
    });
  });
});
