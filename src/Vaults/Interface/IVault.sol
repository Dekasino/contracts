// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IVault {
    function allTimeHigh() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 _underlyingAmount) external;

    function getHighWaterMark() external view returns (uint256 watermark);

    function getShareAmount(uint256 _underlyingAmount) external view returns (uint256);

    function getUnderlyingAmount(uint256 _shareAmount) external view returns (uint256);

    function getUnderlyingBalance() external view returns (uint256);

    function highWaterMark() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function isVaultController(address) external view returns (bool);

    function lockAmounts(uint256) external view returns (uint256);

    function lockBet(uint256 _betId, uint256 _lockAmount) external;

    function maxSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setMaxSupply(uint256 _newSupply) external;

    function setStakingParams(address _newStakingContract, uint256 _newStakingPercent) external;

    function setVaultController(address _controller, bool _status) external;

    function stakingContract() external view returns (address);

    function stakingPercent() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function transferOwnership(address newOwner) external;

    function underlying() external view returns (address);

    function unlockBet(uint256 _betId, uint256 _unlockAmount) external;

    function withdraw(uint256 _shareAmount) external;
}
