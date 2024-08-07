//SPDX-License-Identifier:MIT

import "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Script} from "lib/forge-std/src/Script.sol";
import "../test/mocks/LinkToken.sol";

pragma solidity ^0.8.18;

contract HelperConfig is Script {
    struct networkConfig {
        uint256 entranceFee;
        uint256 interval;
        address coordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackgasLimit;
        address link;
        address account;
    }

    networkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getorCreateAnvilWthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (networkConfig memory) {
        return
            networkConfig({
                entranceFee: 0.1 ether,
                interval: 30,
                coordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 89893997771484702800239423555426967606568758206275980651178817379072674122430,
                callbackgasLimit: 500000,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                account: 0x9110ec73cF857483af9BBD9AEe7ade0CebcB98CE
            });
    }

    function getorCreateAnvilWthConfig() public returns (networkConfig memory) {
        if (activeNetworkConfig.coordinator != address(0)) {
            return activeNetworkConfig;
        }

        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;
        int256 wei_per_unit_link = 300000;

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            baseFee,
            gasPriceLink,
            wei_per_unit_link
        );
        vm.stopBroadcast();

        LinkToken link = new LinkToken();

        return
            networkConfig({
                entranceFee: 0.1 ether,
                interval: 30,
                coordinator: address(vrfCoordinatorMock),
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 0,
                callbackgasLimit: 2500000,
                link: address(link),
                account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
            });
    }
}
