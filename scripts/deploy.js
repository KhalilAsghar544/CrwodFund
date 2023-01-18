// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const address="0x8bed756f4411e94758601be18a94ba76f945daa9";
const duration= 1705563489;

async function main() {
  const CrowdFund = await hre.ethers.getContractFactory("CrowdFund");
  const crowdfund = await CrowdFund.deploy(address,duration);

  await crowdfund.deployed();

  console.log(
    `contract deployed to ${crowdfund.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
