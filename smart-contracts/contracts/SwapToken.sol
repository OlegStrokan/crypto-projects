// SPDX-License-Identifier: MIT 
pragma solidity >=0.7.0 < 0.9.0;


contract StackingDapp is Ownable, ReentrancyGuard {

    using SafeERC20 from IERC20;

    struct UserInfo {

    }

    struct PoolInfo {

    }
    struct Notification {

    }

    uint decimals = 10 ** 18;
    uint public poolCount;
    PoolInfo[] public poolInfo;

    mapping(address => uint256) public depositedTokens;
    mapping(uint256 => mapping(address => UserInfo)) public UserInfo;

    Notification[] public notifications;

    function addPool() {}

    function deposit() {}

    function withdraw() {}

    function _calcPendingReward() { }

    function pendingReward() {}

    function sweep() {}

    function modityPool() {}
    
    function claimReward() {}

    function _createNotification() {}

    function getNotifications() {}
}