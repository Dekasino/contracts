//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract BaseVault is ERC20, Ownable {
    IERC20Metadata public immutable underlying;
    uint8 internal immutable _decimals;
    uint256 internal immutable scalingFactor;

    uint256 public highWaterMark;
    uint256 public allTimeHigh;

    uint256 public lastUpdatedTime;
    uint256 public lastPrice;
    uint256 public updatePeriod;
    int256 public currentAPY;

    address public stakingContract;
    uint256 public stakingPercent;
    uint256 public maxSupply;

    mapping(address => bool) public isVaultController;
    mapping(uint256 => uint256) internal lockAmounts;

    uint256 public totalLockedAmount;

    event BetLocked(uint256 _betId, uint256 _lockAmount, uint256 timestamp);
    event BetUnlocked(uint256 _betId, uint256 _unlockAmount, uint256 timestamp);

    modifier onlyController() {
        require(isVaultController[msg.sender], "Unauthorized");
        _;
    }

    constructor(address _underlying, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        underlying = IERC20Metadata(_underlying);
        _decimals = underlying.decimals();
        scalingFactor = 10 ** _decimals;
        maxSupply = 50_000 * 10 ** _decimals;

        highWaterMark = scalingFactor;
        allTimeHigh = highWaterMark;
        updatePeriod = 7 days;
        lastPrice = 10 ** _decimals;

        stakingContract = address(0xdeadbeef);
        stakingPercent = 300;
    }

    function deposit(uint256 _underlyingAmount) external {
        uint256 amountToMint = totalSupply() == 0 ? _underlyingAmount : getShareAmount(_underlyingAmount);
        require(totalSupply() + amountToMint <= maxSupply, "Max supply exceeded");
        underlying.transferFrom(msg.sender, address(this), _underlyingAmount);
        _mint(msg.sender, amountToMint);
    }

    function withdraw(uint256 _shareAmount) external {
        uint256 amountToWithdraw = getUnderlyingAmount(_shareAmount);
        require(amountToWithdraw <= getUnderlyingBalance() - totalLockedAmount, "Bet in progress, please wait");
        _burn(msg.sender, _shareAmount);
        underlying.transfer(msg.sender, amountToWithdraw);
    }

    function lockBet(uint256 _betId, uint256 _lockAmount) external onlyController {
        require(totalLockedAmount + _lockAmount <= getUnderlyingBalance(), "Insufficient vault balance");
        require(lockAmounts[_betId] == 0, "Invalid bet id");

        totalLockedAmount += _lockAmount;
        lockAmounts[_betId] = _lockAmount;
        emit BetLocked(_betId, _lockAmount, block.timestamp);
    }

    function unlockBet(uint256 _betId, uint256 _unlockAmount) external onlyController {
        uint256 amount = lockAmounts[_betId];
        require(amount >= _unlockAmount, "Invalid unlock amount");
        lockAmounts[_betId] = 0;

        totalLockedAmount -= amount;

        if (_unlockAmount > 0) {
            underlying.transfer(msg.sender, _unlockAmount);
        }

        // solhint-disable reentrancy
        highWaterMark = getHighWaterMark();

        if (highWaterMark > allTimeHigh) {
            uint256 totalProfits = (highWaterMark - allTimeHigh) * totalSupply();
            uint256 stakingShare = (totalProfits * stakingPercent / 1000) / scalingFactor;
            underlying.transfer(stakingContract, stakingShare);

            highWaterMark = getHighWaterMark();
            allTimeHigh = highWaterMark;
        }

        updateAPY();

        emit BetUnlocked(_betId, _unlockAmount, block.timestamp);
    }

    function updateAPY() public {
        if (block.timestamp >= lastUpdatedTime + updatePeriod) {
            uint256 currentPrice = getUnderlyingAmount(scalingFactor);
            int256 difference = int256(currentPrice) - int256(lastPrice);
            currentAPY = difference * 360 days / (int256(block.timestamp) - int256(lastUpdatedTime));
            lastPrice = currentPrice;
            lastUpdatedTime = block.timestamp;
        }
    }

    function setUpdatePeriod(uint256 _newUpdatePeriod) external onlyOwner {
        updatePeriod = _newUpdatePeriod;
    }

    function setVaultController(address _controller, bool _status) external onlyOwner {
        isVaultController[_controller] = _status;
    }

    function setStakingParams(address _newStakingContract, uint256 _newStakingPercent) external onlyOwner {
        stakingContract = _newStakingContract;
        stakingPercent = _newStakingPercent;
    }

    function setMaxSupply(uint256 _newSupply) external onlyOwner {
        require(_newSupply > totalSupply() , "Invalid max supply");
        maxSupply = _newSupply;
    }

    function getUnderlyingAmount(uint256 _shareAmount) public view returns (uint256) {
        return (_shareAmount * getUnderlyingBalance() / totalSupply());
    }

    function getShareAmount(uint256 _underlyingAmount) public view returns (uint256) {
        return (_underlyingAmount * totalSupply() / getUnderlyingBalance());
    }

    function getUnderlyingBalance() public view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    function getHighWaterMark() public view returns (uint256 watermark) {
        return (getUnderlyingBalance() * scalingFactor / totalSupply());
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
