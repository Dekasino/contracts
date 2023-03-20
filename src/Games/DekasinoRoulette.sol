//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

import { RrpRequesterV0 } from "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import { IVault } from "src/Vaults/Interface/IVault.sol";

contract DekasinoRoulette is Ownable, RrpRequesterV0 {
    error BetAmount();
    error MinBetFragment();
    error TokenNotSupported();
    error InvalidBet();

    enum BetStatus {
        Invalid,
        InProgress,
        Won,
        Lost,
        Refunded
    }

    struct Bet {
        bytes32 requestId;
        address player;
        address token;
        uint256[38] betAmounts;
        uint256 totalBet;
        uint256 wonAmount;
        uint256 timestamp;
        uint256 rolledNumber;
        BetStatus status;
    }

    struct Token {
        bool isSupported;
        IVault vault;
        uint256 minBet;
        uint256 minPossibleFragment;
        uint256 maxBet;
    }

    /**
     * Arbitrum goerli TESTNET
     */
    address internal airnode = 0x6238772544f029ecaBfDED4300f13A3c4FE84E1D;
    address internal rrpAddress = 0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd;
    bytes32 internal endpointIdUint256 = 0xfb6d017bb87991b7495f563db3c8cf59ff87b09781947bb1e417006ad7f55a78;

    address payable public sponsorWallet;
    uint256 public gasForProcessing;
    uint256 public waitTimeUntilRefund;

    mapping(bytes32 => address) private idToUser;
    mapping(bytes32 => uint256) private idToSystemIndex;
    mapping(bytes32 => uint256) private idToUserIndex;

    Bet[] public allBets;
    mapping(address => Bet[]) public userBets;
    mapping(address => Token) public tokens;

    event BetPlaced(
        address indexed user, uint256 requestId, uint256 betAmount, uint256[38] bets, address token, uint256 timestamp
    );
    event WheelSpinned(
        address indexed user,
        uint256 requestId,
        address token,
        uint256 rolledNumber,
        uint256 totalBet,
        uint256 wonAmount,
        uint256 timestamp
    );

    constructor() RrpRequesterV0(rrpAddress) {
        gasForProcessing = 0.0005 ether;
        waitTimeUntilRefund = 1 hours;
    }

    function placeBet(address _token, uint256[38] memory _betAmounts) external payable {
        require(msg.value >= gasForProcessing, "Insufficient fees");
        (uint256 total, uint256 highest) = _validateBet(_token, _betAmounts);
        IERC20 token = IERC20(_token);

        uint256 maxPayout = highest * 35;

        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode, endpointIdUint256, address(this), sponsorWallet, address(this), this.fulfillUint256.selector, ""
        );

        tokens[_token].vault.lockBet(uint256(requestId), maxPayout);

        allBets.push(
            Bet(requestId, msg.sender, _token, _betAmounts, total, 0, block.timestamp, 0, BetStatus.InProgress)
        );
        userBets[msg.sender].push(
            Bet(requestId, msg.sender, _token, _betAmounts, total, 0, block.timestamp, 0, BetStatus.InProgress)
        );

        idToUser[requestId] = msg.sender;
        idToSystemIndex[requestId] = allBets.length - 1;
        idToUserIndex[requestId] = userBets[msg.sender].length - 1;

        token.transferFrom(msg.sender, address(this), total);
        sponsorWallet.transfer(msg.value);

        emit BetPlaced(msg.sender, uint256(requestId), total, _betAmounts, _token, block.timestamp);
    }

    function fulfillUint256(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp {
        uint256 qrngUint256 = abi.decode(data, (uint256));
        uint256 rolledNumber = qrngUint256 % 38; //0 to 38, 0 = 0, 1 = 1, 2 = 2 ... 37 = 00

        Bet storage system = allBets[idToSystemIndex[requestId]];
        Bet storage user = userBets[system.player][idToUserIndex[requestId]];
        Bet memory memBet = allBets[idToSystemIndex[requestId]];

        IVault vault = tokens[memBet.token].vault;
        IERC20 token = IERC20(memBet.token);

        uint256 wonAmount = memBet.betAmounts[rolledNumber] * 35;
        uint256 amountToVault = memBet.totalBet - memBet.betAmounts[rolledNumber];
        token.transfer(address(vault), amountToVault);
        vault.unlockBet(uint256(requestId), wonAmount);
        wonAmount += memBet.betAmounts[rolledNumber];

        if (wonAmount > 0) {
            token.transfer(memBet.player, wonAmount);
            user.status = BetStatus.Won;
            system.status = BetStatus.Won;
            user.wonAmount = wonAmount;
            system.wonAmount = wonAmount;
        } else {
            user.status = BetStatus.Lost;
            system.status = BetStatus.Lost;
        }

        user.rolledNumber = rolledNumber;
        system.rolledNumber = rolledNumber;

        emit WheelSpinned(
            memBet.player, uint256(requestId), memBet.token, rolledNumber, memBet.totalBet, wonAmount, block.timestamp
        );
    }

    function refundBet(uint256[] calldata _betIds) external onlyOwner { 
        uint256 len = _betIds.length;
        for(uint256 i; i < len; i++) {
            Bet memory bet = allBets[_betIds[i]];
            require(bet.status == BetStatus.InProgress,"Invalid bet");
            require(block.timestamp >= bet.timestamp + waitTimeUntilRefund,"Too early");

            allBets[_betIds[i]].status = BetStatus.Refunded;
            userBets[bet.player][idToUserIndex[bet.requestId]].status = BetStatus.Refunded;

            IERC20(bet.token).transfer(bet.player,bet.totalBet);
            tokens[bet.token].vault.unlockBet(_betIds[i],0);
        }
    }

    function _validateBet(
        address _token,
        uint256[38] memory _betAmounts
    )
        internal
        view
        returns (uint256 totalBet, uint256 highestBet)
    {
        Token memory tkn = tokens[_token];
        if (!tkn.isSupported) revert TokenNotSupported();
        for (uint256 i = 0; i < 38;) {
            if (_betAmounts[i] > 0) {
                if (_betAmounts[i] <= tkn.minPossibleFragment) revert MinBetFragment();
                if (_betAmounts[i] > highestBet) highestBet = _betAmounts[i];
                totalBet += _betAmounts[i];
            }
            unchecked {
                i++;
            }
        }
        if (totalBet < tkn.minBet || totalBet > tkn.maxBet) revert BetAmount();
    }

    function setToken(
        address _token,
        bool _isSupported,
        IVault _vault,
        uint256 _minBet,
        uint256 _maxBet
    )
        external
        onlyOwner
    {
        Token storage t = tokens[_token];

        t.isSupported = _isSupported;
        t.vault = _vault;
        t.minBet = _minBet;
        t.maxBet = _maxBet;

        t.minPossibleFragment = _minBet / 18;
    }

    function setOracle(
        address _airnode,
        address payable _sponsorWallet,
        bytes32 _endpointIdUint256,
        uint256 _gasAmount
    )
        external
        onlyOwner
    {
        airnode = _airnode;
        sponsorWallet = _sponsorWallet;
        endpointIdUint256 = _endpointIdUint256;
        gasForProcessing = _gasAmount;
    }

    function setTimeForRefund(uint256 _newTime) external onlyOwner {
        require(_newTime > 1 hours, "Invalid Time");
        waitTimeUntilRefund = _newTime;
    }

    function getTotalBetsByUser(address _user) external view returns (uint256) {
        return userBets[_user].length;
    }

    function getTotalBets() external view returns (uint256) {
        return allBets.length;
    }

    function getBetsOfUser(address user, uint256 from, uint256 to) external view returns (Bet[] memory bets) {
        bets = new Bet[](to - from + 1);
        uint256 count;
        for (uint256 i = from; i <= to; i++) {
            bets[count] = userBets[user][i];
            count++;
        }
    }

    function getAllBets(uint256 from, uint256 to) external view returns (Bet[] memory bets) {
        bets = new Bet[](to - from + 1);
        uint256 count;
        for (uint256 i = from; i <= to; i++) {
            bets[count] = allBets[i];
            count++;
        }
    }
}
