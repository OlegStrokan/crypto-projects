// scripts/deploy.js

const { ethers } = require("hardhat");

async function main() {
  const ERC20 = await ethers.getContractFactory("ERC20");
  const erc20Token = await ERC20.deploy("MyToken", "MTK");
  await erc20Token.deployed();
  console.log("ERC20 Token deployed to:", erc20Token.address);

  const TokenICO = await ethers.getContractFactory("TokenICO");
  const tokenSalePrice = ethers.utils.parseEther("0.01");
  const tokenICO = await TokenICO.deploy(erc20Token.address, tokenSalePrice);
  await tokenICO.deployed();
  console.log("TokenICO deployed to:", tokenICO.address);

  const StackingDapp = await ethers.getContractFactory("StackingDapp");
  const stackingDapp = await StackingDapp.deploy();
  await stackingDapp.deployed();
  console.log("StackingDapp deployed to:", stackingDapp.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
