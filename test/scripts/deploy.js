const StakeToken = artifacts.require("StakeToken");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(StakeToken);
  const stakeToken = await StakeToken.deployed();
  
  console.log("StakeToken deployed to:", stakeToken.address);
  console.log("Owner address:", accounts[0]);
  
  // Додаткові налаштування для testnet/mainnet
  if (network !== "development") {
    console.log("Contract verification info:");
    console.log("Constructor arguments: []");
  }
};
