//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract BaseVault is ERC20, Ownable {
    IERC20Metadata public immutable underlying;
    uint8 internal immutable _decimals;

    uint256 public highWaterMark;
    uint256 public allTimeHigh;
    address public stakingContract;

    mapping(address => bool) public isVaultController;

    constructor(address _underlying, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        underlying = IERC20Metadata(_underlying);
        _decimals = underlying.decimals();
    }

    function deposit(uint256 _underlyingAmount) external {
        uint256 amountToMint = getShareAmount(_underlyingAmount);
        underlying.transferFrom(msg.sender, address(this), _underlyingAmount);
        _mint(msg.sender, amountToMint);
    }

    function withdraw(uint256 _shareAmount) external {
        uint256 amountToWithdraw = getUnderlyingAmount(_shareAmount);
        _burn(msg.sender, _shareAmount);
        underlying.transfer(msg.sender, amountToWithdraw);
    }

    function setVaultController(address _controller, bool _status) external onlyOwner {
        isVaultController[_controller] = _status;
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

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
