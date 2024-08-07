//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {AutomationCompatibleInterface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__notEnoughEthSend();
    error Raffle__transactionFailed();
    error Raffle__StateNotOpen();
    error Raffle__UpKeepNotNeeded(
        uint256 balance,
        uint256 players,
        uint256 raffleState
    );

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    RaffleState public s_raffleState;

    uint16 constant CONFIRMATION = 3;
    uint32 constant NUM_WORDS = 1;
    uint256 immutable i_entranceFee;
    uint256 immutable i_interval;
    bytes32 immutable i_gasLane;
    uint256 immutable i_subscriptionId;
    uint32 immutable i_callbackgasLimit;
    address payable[] s_players;
    address payable s_recentWinner;
    uint256 s_timeStamp;

    //Events
    event EnteredRaffle(address indexed player);
    event RaffleWinner(address indexed player);
    event RequestRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address coordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackgasLimit
    ) VRFConsumerBaseV2Plus(coordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackgasLimit = callbackgasLimit;
        s_timeStamp = block.timestamp;

        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__notEnoughEthSend();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__StateNotOpen();
        }
        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upKeepNeeded, bytes memory /* calldata*/) {
        bool timeHasPassed = (block.timestamp - s_timeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upKeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upKeepNeeded, "0x0");
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
        //create rng
        VRFV2PlusClient.RandomWordsRequest memory request = (
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: CONFIRMATION,
                callbackGasLimit: i_callbackgasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        //use random number

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);

        emit RequestRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256,
        /*requestId*/
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_timeStamp = block.timestamp;
        // console.log(address(this).balance);

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__transactionFailed();
        }

        emit RaffleWinner(winner);
    }

    //getters

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() public view returns (RaffleState) {
        return (s_raffleState);
    }

    function getPlayer(uint256 index) external view returns (address payable) {
        return s_players[index];
    }

    function getTimeStamps() external view returns (uint256) {
        return s_timeStamp;
    }

    function getRecentWinner() external view returns (address payable) {
        return s_recentWinner;
    }

    // function getInterval() external view returns (uint256) {
    //     return i_interval;
    // }

    // function getGasLane() external view returns (bytes32) {
    //     return i_gasLane;
    // }

    // function getSubscriptionId() external view returns (uint256) {
    //     return i_subscriptionId;
    // }

    // function getCallbackGasLimit() external view returns (uint32) {
    //     return i_callbackgasLimit;
    // }

    //setters
    function setRaffleState(uint256 raffleState) public {
        s_raffleState = RaffleState(raffleState);
    }
}
