//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "src/Vaults/Interface/IVault.sol";

contract DekasinoRoulette is Ownable, RrpRequesterV0 {
    error BetAmount();
    error MinBetFragment();
    error TokenNotSupported();
    error InvalidBet();

    struct Bet {
        bytes32 requestId;
        address player;
        address token;
        uint8[38] betAmounts;
        uint256 totalBet;
        uint8 status;
    }

    struct Token {
        bool isSupported;
        IVault vault;
        uint256 minBet;
        uint256 minPossibleFragment;
        uint256 maxBet;
    }

    /**
     * Goerli TESTNET
     */
    address internal airnode = 0x6238772544f029ecaBfDED4300f13A3c4FE84E1D;
    address internal rrpAddress = 0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd;
    bytes32 internal endpointIdUint256 = 0xfb6d017bb87991b7495f563db3c8cf59ff87b09781947bb1e417006ad7f55a78;
    address internal sponsorWallet;

    mapping(bytes32 => address) private idToUser;
    mapping(bytes32 => uint256) private idToSystemIndex;
    mapping(bytes32 => uint256) private idToUserIndex;

    mapping(uint256 => bool) private validChoice;

    Bet[] public allBets;
    mapping(address => Bet[]) public userBets;
    mapping(address => Token) public tokens;

    event BetPlaced(address indexed user, uint256 betAmount, uint8[38] bets, address token, uint256 timestamp);
    event WheelSpinned(
        address indexed user,
        address token,
        uint256 rolledNumber,
        uint256 totalBet,
        uint256 wonAmount,
        uint256 timestamp
    );

    constructor() RrpRequesterV0(rrpAddress) {
        validChoice[1] = true; //Straight
        validChoice[2] = true; //Split
        validChoice[3] = true; //Street
        validChoice[4] = true; //Corner
        validChoice[5] = true; //0,00,1,2,3
        validChoice[6] = true; //Six line
        validChoice[12] = true; //Dozen/Column
        validChoice[18] = true; //High/Low/Red/Black/Odd/Even
    }

    function placeBet(address _token, uint8[38] memory _betAmounts) external {
        (uint256 total, uint256 highest) = _validateBet(_token, _betAmounts);
        IERC20 token = IERC20(_token);

        token.transferFrom(msg.sender, address(this), total);
        uint256 maxPayout = highest * 35;

        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode, endpointIdUint256, address(this), sponsorWallet, address(this), this.fulfillUint256.selector, ""
        );

        tokens[_token].vault.lockBet(uint256(requestId), maxPayout);

        allBets.push(Bet(requestId, msg.sender, _token, _betAmounts, total, 0));
        userBets[msg.sender].push(Bet(requestId, msg.sender, _token, _betAmounts, total, 0));

        idToUser[requestId] = msg.sender;
        idToSystemIndex[requestId] = allBets.length - 1;
        idToUserIndex[requestId] = userBets[msg.sender].length - 1;

        emit BetPlaced(msg.sender, total, _betAmounts, _token, block.timestamp);
    }

    function fulfillUint256(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp {
        uint256 qrngUint256 = abi.decode(data, (uint256));
        uint256 rolledNumber = qrngUint256 % 38; //0 to 38, 0 = 00, 1 = 0, 2 = 1 ... 37 = 36

        Bet storage system = allBets[idToSystemIndex[requestId]];
        Bet storage user = userBets[system.player][idToUserIndex[requestId]];
        IVault vault = tokens[user.token].vault;
        IERC20 token = IERC20(user.token);

        uint256 wonAmount = user.betAmounts[rolledNumber] * 35;
        uint256 amountToVault = user.totalBet - user.betAmounts[rolledNumber];
        token.transfer(address(vault), amountToVault);
        vault.unlockBet(uint256(requestId), wonAmount);
        wonAmount += user.betAmounts[rolledNumber];

        if (wonAmount > 0) {
            token.transfer(user.player, wonAmount);
            user.status = 1;
            system.status = 1;
        }

        emit WheelSpinned(user.player, user.token, rolledNumber, user.totalBet, wonAmount, block.timestamp);
    }

    function _validateBet(
        address _token,
        uint8[38] memory _betAmounts
    )
        internal
        view
        returns (uint256 totalBet, uint256 highestBet)
    {
        Token memory tkn = tokens[_token];
        if (!tkn.isSupported) revert TokenNotSupported();
        uint256 totalNumbers;
        for (uint256 i = 0; i < 38;) {
            if (_betAmounts[i] > 0) {
                if (_betAmounts[i] < tkn.minPossibleFragment) revert MinBetFragment();
                if (_betAmounts[i] > highestBet) highestBet = _betAmounts[i];
                totalNumbers++;
                totalBet += _betAmounts[i];
            }
            unchecked {
                i++;
            }
        }
        if (totalBet < tkn.minBet || totalBet > tkn.maxBet) revert BetAmount();
        if (!validChoice[totalNumbers]) revert InvalidBet();
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

    function setSponsorWallet(address _newWallet) external onlyOwner {
        sponsorWallet = _newWallet;
    }

    function getTotalBetsByUser(address _user) external view returns (uint256) {
      return userBets[_user].length;
    }

    function getTotalBets() external view returns (uint256) {
      return allBets.length;
    }

    function getBetsOfUser(address user, uint256 from, uint256 to) external view returns (Bet[] memory bets) {
        bets = new Bet[](to - from + 1);
        for (uint256 i = from; i <= to; i++) {
            bets[i] = userBets[user][i];
        }
    }

    function getAllBets(uint256 from, uint256 to) external view returns (Bet[] memory bets) {
        bets = new Bet[](to - from + 1);
        for (uint256 i = from; i <= to; i++) {
            bets[i] = allBets[i];
        }
    }
}
