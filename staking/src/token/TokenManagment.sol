// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TokenManagment {
    address public owner;
    address public tokenAddress;
    uint256 public tokenSalePrice; // Price in wei per token
    uint256 public soldTokens;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(address _tokenAddress, uint256 _tokenSalePrice) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        tokenSalePrice = _tokenSalePrice;
    }

    // Allows users to buy tokens
    function buyToken(uint256 _tokenAmount) public payable {
        uint256 requiredEth = _tokenAmount * tokenSalePrice;
        require(msg.value == requiredEth, "Incorrect ETH amount sent");

        ERC20 token = ERC20(tokenAddress);
        uint256 tokenAmountWithDecimals = _tokenAmount * 10 ** token.decimals();

        require(
            token.balanceOf(address(this)) >= tokenAmountWithDecimals,
            "Insufficient tokens available"
        );
        require(
            token.transfer(msg.sender, tokenAmountWithDecimals),
            "Token transfer failed"
        );

        payable(owner).transfer(msg.value);
        soldTokens += _tokenAmount;
    }

    // Allows users to sell tokens and receive ETH
    function sellToken(uint256 _tokenAmount) public {
        ERC20 token = ERC20(tokenAddress);
        uint256 tokenAmountWithDecimals = _tokenAmount * 10 ** token.decimals();
        uint256 ethAmount = _tokenAmount * tokenSalePrice;

        require(
            token.balanceOf(msg.sender) >= tokenAmountWithDecimals,
            "Insufficient token balance"
        );
        require(
            token.allowance(msg.sender, address(this)) >=
                tokenAmountWithDecimals,
            "Insufficient token allowance"
        );
        require(
            address(this).balance >= ethAmount,
            "Insufficient ETH balance in contract"
        );

        require(
            token.transferFrom(
                msg.sender,
                address(this),
                tokenAmountWithDecimals
            ),
            "Token transfer failed"
        );
        payable(msg.sender).transfer(ethAmount);
    }

    // Allows the contract owner to withdraw ETH from the contract
    function withdrawETH(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient ETH balance");
        payable(owner).transfer(amount);
    }

    // Allows the contract owner to withdraw all ETH from the contract
    function withdrawAllETH() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner).transfer(balance);
    }
}
