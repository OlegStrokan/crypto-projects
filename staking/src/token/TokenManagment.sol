// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenManagment {
    address public owner;
    address public tokenAddress;
    uint256 public tokenSalePrice;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only contract owner can perform this action"
        );
        _;
    }

    constructor(address _tokenAddress, uint256 _tokenSalePrice) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        tokenSalePrice = _tokenSalePrice;
    }

    function updateTokenSalePrice(uint256 _tokenSalePrice) public onlyOwner {
        tokenSalePrice = _tokenSalePrice;
    }

    function buyToken(uint256 _tokenAmount) public payable {
        uint256 amountRequired = _tokenAmount * tokenSalePrice;
        require(msg.value >= amountRequired, "Insufficient Ether provided");

        ERC20 token = ERC20(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(
            _tokenAmount <= contractBalance,
            "Insufficient tokens available"
        );

        require(
            token.transfer(msg.sender, _tokenAmount),
            "Token transfer failed"
        );
        payable(owner).transfer(msg.value);
    }

    function withdrawAllTokens() public onlyOwner {
        ERC20 token = ERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(token.transfer(owner, balance), "Token withdrawal failed");
    }
}
