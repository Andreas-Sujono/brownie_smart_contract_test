// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    AggregatorV3Interface internal ethToUsdPriceFeed;
    uint256 public usdEntryFee;
    address public recentWinner;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        ON_PROGRESS
    }
    LOTTERY_STATE public lotteryState;
    uint256 public fee;
    bytes32 keyHash;
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        ethToUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        usdEntryFee = 50 * (10**18); //50 USD to wei
        lotteryState = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyHash = _keyHash;
    }

    function enter() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "lottery is not open yet");
        require(msg.value >= getEntranceFee(), "entrance fee is not achieved");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = ethToUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * (10**10); //18 decimal places (wei), $2000 * 10000000 (default)* 1000000000 wei
        return ((usdEntryFee * 10**18) / adjustedPrice); //(50 / price) * 10**18 wei
    }

    function startLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "lottery is not closed");
        lotteryState = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        lotteryState = LOTTERY_STATE.ON_PROGRESS;
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lotteryState == LOTTERY_STATE.ON_PROGRESS,
            "Not finished calculating"
        );
        require(_randomness > 0, "random not found");

        uint256 winnerIndex = _randomness % players.length;
        address payable winner = players[winnerIndex];
        winner.transfer(address(this).balance);
        recentWinner = winner;

        players = new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
    }
}
