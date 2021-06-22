const { ethers, upgrades } = require('hardhat');

/*
  Describing the tests, for the staking
  contract.
*/
describe('StakingContract: Testing Staking Contract', () => {
  let stakingC;
  let owner;

  before(async () => {
    [owner] = await ethers.getSigners();

    const StakingContract = await ethers.getContractFactory('StakingContract');
    stakingC = await upgrades.deployProxy(StakingContract);
    await stakingC.deployed();
  });

  it('should deploy the contract with the proxy', async () => {
    console.log('StakingContract deployed to:', stakingC.address);
  });
});
