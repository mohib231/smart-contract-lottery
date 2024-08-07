//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import "lib/forge-std/src/Test.sol";
import "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

import {console} from "lib/forge-std/src/console.sol";
// import {Vm} from "lib/forge-std/src/Vm.sol";
// import {RaffleState} from "../../src/RaffleEnums.sol";

contract RaffleTest is Test {
    /*Events */
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address coordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackgasLimit;
    address link;
    address account;

    address PLAYER = makeAddr("player");
    uint256 PLAYER_BALANCE = 10 ether;

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();

        (
            entranceFee,
            interval,
            coordinator,
            gasLane,
            subscriptionId,
            callbackgasLimit,
            link,
            account
        ) = helperConfig.activeNetworkConfig();
        console.log(account);
        vm.deal(PLAYER, PLAYER_BALANCE);
    }

    // function test_constructorOfRaffle() public view {
    //     assertEq(
    //         raffle.getEntranceFee(),
    //         entranceFee,
    //         "Entrance fee should match"
    //     );
    //     assertEq(raffle.getInterval(), interval, "Interval should match");
    //     assertEq(raffle.getGasLane(), gasLane, "Gas lane should match");
    //     assertEq(
    //         raffle.getCallbackGasLimit(),
    //         callbackgasLimit,
    //         "Callback gas limit should match"
    //     );
    //     assertEq(
    //         uint256(raffle.getRaffleState()),
    //         uint256(Raffle.RaffleState.OPEN),
    //         "Raffle state should be OPEN"
    //     );

    // }

    function test_getRaffleInitialStateIsOpen() public view {
        assert((raffle.getRaffleState() == Raffle.RaffleState.OPEN));
    }

    function test_RaffleWhenYouDontHaveEnoughEth() public {
        vm.prank(PLAYER);

        vm.expectRevert(Raffle.Raffle__notEnoughEthSend.selector);

        raffle.enterRaffle();
    }

    function test_RaffleRecordPlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(PLAYER == playerRecorded);
    }

    function test_emitEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));

        emit EnteredRaffle(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
    }

    function test_PlayersDoNotEnterWhenRaffleSateIsCalculating()
        public
        raffleEntered
    {
        raffle.performUpkeep("");
        //act
        vm.expectRevert(Raffle.Raffle__StateNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        //assert
    }
    //test when money is not provided

    function test_upkeepWhenBalanceIsNotEntered() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upKeepNeeded);
    }

    //test when raffle is not calculating

    function test_upkeepneededFalseWhenStateIsCalculating()
        public
        raffleEntered
    {
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    //checkupkeepReturnsFalseWhenEnoughTimeHasPassed

    function test_upkeepNeedReturnsFalseWhenEnoughTimeHasPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.roll(block.number + 1);
        raffle.setRaffleState(0);
        // raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // console.log(upkeepNeeded);
        assert(!upkeepNeeded);
    }

    function test_upkeepNeededReturnsTrueWhenAllTheParamsAreGood()
        public
        raffleEntered
    {
        raffle.setRaffleState(0);

        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        assertTrue(upKeepNeeded);
    }

    //Perform upkeepTest

    function test_performUpKeepIsOnlyTrueWhenCheckUpKeepIsTrue()
        public
        raffleEntered
    {
        raffle.setRaffleState(0);
        raffle.performUpkeep("");
    }

    function test_performUpKeepNotNeededRevertsWhenUpKeepNeededIsFalse()
        public
    {
        uint256 fee = 0;
        uint256 numOfPlayers = 1;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        fee = entranceFee + fee;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                fee,
                numOfPlayers,
                rState
            )
        );
        raffle.performUpkeep("");
    }

    function test_PerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEntered
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        console.logBytes32(entries[1].topics[1]);

        bytes32 requestId = entries[1].topics[1];
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function test_fulfillRandomWordsCanOnlyBeCallWhenPerformUpKeepRuns(
        uint256 requestId
    ) public raffleEntered skipFork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        // raffle.performUpkeep("");
        VRFCoordinatorV2_5Mock(coordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );
    }

    function test_fulfillRandomWordsPicksAWinnerResetsAndSendSomeMoney()
        public
        raffleEntered
        skipFork
    {
        uint256 additionalPlayers = 3;
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for (
            uint256 i = startingIndex;
            i <= (startingIndex + additionalPlayers);
            i++
        ) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 startingTime = raffle.getTimeStamps();
        uint256 expectedWinnerStartingBalance = expectedWinner.balance;

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(coordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamps = raffle.getTimeStamps();
        uint256 prize = entranceFee * (additionalPlayers + 1);
        // uint256 prize = address(raffle).balance;
        console.log(winnerBalance);
        console.log(expectedWinnerStartingBalance + prize + entranceFee);
        // console.log(expectedWinner);
        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(
            winnerBalance == expectedWinnerStartingBalance + prize + entranceFee
        );
        assert(startingTime < endingTimeStamps);
    }
}
