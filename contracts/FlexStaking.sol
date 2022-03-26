//SPDX-License-Identifier: UNLICENSED

/// @title Flexible Staking Contract with Variable Emission
/// @author Ace
/// @notice Contract allows you to Single Stake ERC20 token to receive rewards
/// @dev Contract is a modified version of Synthetix implementation to airdrop rewards when owner changes emissions

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FlexStaking is Ownable,ReentrancyGuard{

    IERC20 GRAV;

    uint public rewardRate = 100;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address=>uint) public userRewardPerTokenPaid;
    mapping(address=>uint) public rewards;

    uint private _totalSupply;
    mapping(address=>uint) public balances;

    uint lockedGrav;

    address[] userStaked;

    struct stakeInfo{
        uint userPosition;
        bool userStaked;
    }

    mapping(address=>stakeInfo) userInfo;

    constructor(address _grav){
        GRAV = IERC20(_grav);
    } 

    function rewardPerToken() public view returns(uint){
        if(_totalSupply == 0){
            return 0;
        }
        return rewardPerTokenStored + (
            (rewardRate/1 days) + (block.timestamp - lastUpdateTime) * 1e18 / _totalSupply
        );
    }

    function earned(address account) public view returns(uint){
        return (
            balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18
        ) + rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function stake(uint _amount) external updateReward(msg.sender){
        if(!userInfo[msg.sender].userStaked){
            userInfo[msg.sender] = stakeInfo(userStaked.length,true);
            userStaked.push(msg.sender);
        }
        _totalSupply += _amount;
        balances[msg.sender] += _amount;
        lockedGrav += _amount;
        GRAV.transferFrom(msg.sender,address(this), _amount);
    }

    function withdraw(uint _amount) external updateReward(msg.sender){
        require(balances[msg.sender] >= _amount,"Not enough balance");
        _totalSupply -= _amount;
        balances[msg.sender] -= _amount;
        lockedGrav -= _amount;
        GRAV.transfer(msg.sender,_amount);
        if(balances[msg.sender] == 0){
            uint reward = rewards[msg.sender];
            rewards[msg.sender] = 0;
            GRAV.transfer(msg.sender, reward);
            popUser(msg.sender);
            delete userInfo[msg.sender];
        }
    }

    function popUser(address user) private {
        address lastUser = userStaked[userStaked.length-1];
        uint position = userInfo[user].userPosition;
        userStaked[position] = lastUser;
        userInfo[lastUser].userPosition = position;
        userStaked.pop();
    }

    function getReward() external updateReward(msg.sender){
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        GRAV.transfer(msg.sender, reward);
    }

    function setRewardRate(uint _rate) external onlyOwner{
        rewardRate = _rate;
    }

    function setGrav(address _grav) external onlyOwner{
        GRAV = IERC20(_grav);
    }

    function retrieveGrav() external onlyOwner{
        GRAV.transfer(msg.sender, GRAV.balanceOf(address(this))-lockedGrav);
    }

}