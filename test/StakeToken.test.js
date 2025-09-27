const StakeToken = artifacts.require("StakeToken");
const { time } = require("@openzeppelin/test-helpers");

contract("StakeToken", (accounts) => {
  let stakeToken;
  const [owner, user1, user2] = accounts;

  beforeEach(async () => {
    stakeToken = await StakeToken.new({ from: owner });
    // Переказуємо токени користувачам для тестування
    await stakeToken.transfer(user1, web3.utils.toWei("1000", "ether"), { from: owner });
    await stakeToken.transfer(user2, web3.utils.toWei("1000", "ether"), { from: owner });
  });

  describe("Deployment", () => {
    it("should deploy with correct initial supply", async () => {
      const totalSupply = await stakeToken.totalSupply();
      assert.equal(totalSupply.toString(), web3.utils.toWei("1000000", "ether"));
    });

    it("should have correct name and symbol", async () => {
      const name = await stakeToken.name();
      const symbol = await stakeToken.symbol();
      assert.equal(name, "StakeToken");
      assert.equal(symbol, "STKN");
    });
  });

  describe("Staking", () => {
    it("should allow users to stake tokens", async () => {
      const stakeAmount = web3.utils.toWei("100", "ether");
      await stakeToken.stake(stakeAmount, { from: user1 });

      const stakeInfo = await stakeToken.getStakeInfo(user1);
      assert.equal(stakeInfo[0].toString(), stakeAmount);
    });

    it("should update total staked amount", async () => {
      const stakeAmount = web3.utils.toWei("100", "ether");
      await stakeToken.stake(stakeAmount, { from: user1 });

      const totalStaked = await stakeToken.totalStaked();
      assert.equal(totalStaked.toString(), stakeAmount);
    });
  });

  describe("Unstaking", () => {
    beforeEach(async () => {
      const stakeAmount = web3.utils.toWei("100", "ether");
      await stakeToken.stake(stakeAmount, { from: user1 });
    });

    it("should allow unstaking after minimum period", async () => {
      // Прискорюємо час на 7 днів + 1 секунда
      await time.increase(time.duration.days(7) + 1);
      
      const unstakeAmount = web3.utils.toWei("50", "ether");
      await stakeToken.unstake(unstakeAmount, { from: user1 });

      const stakeInfo = await stakeToken.getStakeInfo(user1);
      assert.equal(stakeInfo[0].toString(), web3.utils.toWei("50", "ether"));
    });

    it("should not allow unstaking before minimum period", async () => {
      const unstakeAmount = web3.utils.toWei("50", "ether");
      
      try {
        await stakeToken.unstake(unstakeAmount, { from: user1 });
        assert.fail("Should have thrown an error");
      } catch (error) {
        assert(error.message.includes("Minimum stake period not met"));
      }
    });
  });

  describe("Rewards", () => {
    it("should calculate rewards correctly", async () => {
      const stakeAmount = web3.utils.toWei("100", "ether");
      await stakeToken.stake(stakeAmount, { from: user1 });

      // Прискорюємо час на 365 днів
      await time.increase(time.duration.days(365));

      const pendingReward = await stakeToken.calculatePendingReward(user1);
      const expectedReward = web3.utils.toWei("10", "ether"); // 10% від 100

      // Перевіряємо з допуском через можливі розбіжності в часі
      assert.approximately(
        parseFloat(web3.utils.fromWei(pendingReward)),
        parseFloat(web3.utils.fromWei(expectedReward)),
        0.1
      );
    });
  });
});
