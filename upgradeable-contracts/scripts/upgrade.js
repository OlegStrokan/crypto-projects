const { ethers, upgrades } = require("hardhat");

async function main() {
  const contact = await ethers.getContractFactory("MeinkampfV2");
  const contactProxy = await upgrades.upgradeProxy(process.env.PROXY, contact);
  console.log("Your upgraded proxy is done!", contactProxy.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
