// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakeToken is ERC20, Ownable, ReentrancyGuard {
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**18; // 1 мільйон токенів
    uint256 public constant REWARD_RATE = 10; // 10% річних
    uint256 public constant MIN_STAKE_PERIOD = 7 days;
    
    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        uint256 rewardDebt;
    }
    
    mapping(address => StakeInfo) public stakes;
    mapping(address => uint256) public rewards;
    
    uint256 public totalStaked;
    uint256 public rewardPool;
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardPoolRefilled(uint256 amount);

    constructor() ERC20("StakeToken", "STKN") {
        _mint(msg.sender, INITIAL_SUPPLY);
        rewardPool = INITIAL_SUPPLY / 10; // 10% для винагород
    }

    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        
        _updateReward(msg.sender);
        
        _transfer(msg.sender, address(this), _amount);
        
        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].timestamp = block.timestamp;
        totalStaked += _amount;
        
        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(stakes[msg.sender].amount >= _amount, "Insufficient staked amount");
        require(
            block.timestamp >= stakes[msg.sender].timestamp + MIN_STAKE_PERIOD,
            "Minimum stake period not met"
        );
        
        _updateReward(msg.sender);
        
        stakes[msg.sender].amount -= _amount;
        totalStaked -= _amount;
        
        _transfer(address(this), msg.sender, _amount);
        
        emit Unstaked(msg.sender, _amount);
    }

    function claimReward() external nonReentrant {
        _updateReward(msg.sender);
        
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards available");
        require(rewardPool >= reward, "Insufficient reward pool");
        
        rewards[msg.sender] = 0;
        rewardPool -= reward;
        
        _transfer(address(this), msg.sender, reward);
        
        emit RewardClaimed(msg.sender, reward);
    }

    function _updateReward(address _user) internal {
        if (stakes[_user].amount > 0) {
            uint256 stakingTime = block.timestamp - stakes[_user].timestamp;
            uint256 reward = (stakes[_user].amount * REWARD_RATE * stakingTime) / (365 days * 100);
            rewards[_user] += reward;
            stakes[_user].timestamp = block.timestamp;
        }
    }

    function getStakeInfo(address _user) external view returns (uint256, uint256, uint256) {
        return (stakes[_user].amount, stakes[_user].timestamp, rewards[_user]);
    }

    function calculatePendingReward(address _user) external view returns (uint256) {
        if (stakes[_user].amount == 0) {
            return rewards[_user];
        }
        
        uint256 stakingTime = block.timestamp - stakes[_user].timestamp;
        uint256 pendingReward = (stakes[_user].amount * REWARD_RATE * stakingTime) / (365 days * 100);
        
        return rewards[_user] + pendingReward;
    }

    function refillRewardPool(uint256 _amount) external onlyOwner {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        _transfer(msg.sender, address(this), _amount);
        rewardPool += _amount;
        emit RewardPoolRefilled(_amount);
    }

    function emergencyWithdraw() external nonReentrant {
        uint256 stakedAmount = stakes[msg.sender].amount;
        require(stakedAmount > 0, "No staked amount");
        
        stakes[msg.sender].amount = 0;
        stakes[msg.sender].timestamp = 0;
        rewards[msg.sender] = 0;
        totalStaked -= stakedAmount;
        
        _transfer(address(this), msg.sender, stakedAmount);
        
        emit Unstaked(msg.sender, stakedAmount);
    }
}
