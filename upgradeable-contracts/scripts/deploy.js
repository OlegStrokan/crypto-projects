const { ethers, upgrades } = require("hardhat");

async function main() {
  const contract = await ethers.getContractFactory("Meinkampf");
  const contractProxy = await upgrades.deployProxy(contract, [42], {
    initializer: "store",
  });
  console.log("proxy deployed to:", contractProxy.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
