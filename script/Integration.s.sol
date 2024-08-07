//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {HelperConfig} from "./HelperConfig.s.sol";
import "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Script} from "lib/forge-std/src/Script.sol";
import "../test/mocks/LinkToken.sol";
import "lib/foundry-devops/src/DevOpsTools.sol";

contract Integration is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address coordinator, , , , , address account) = helperConfig
            .activeNetworkConfig();
        (uint256 subId, ) = createSubscription(coordinator, account);
        return (subId, coordinator);
    }

    function createSubscription(
        address vrfCoordinator,
        address account
    ) public returns (uint256, address) {
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        return (subId, vrfCoordinator);
    }

    function run() external {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 51260618190689957397893829973;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address coordinator,
            ,
            uint256 subId,
            ,
            address link,
            address account
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(coordinator, subId, link,account);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subId,
        address link,
        address account
    ) public {
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address contractToAddToVRF) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address coordinator,
            ,
            uint256 subId,
            ,
            ,
            address account
        ) = helperConfig.activeNetworkConfig();
        addConsumer(contractToAddToVRF, coordinator, subId,account);
    }

    function addConsumer(
        address contractToAddToVRF,
        address vrfCoordinator,
        uint256 subId,
        address account
    ) public {
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            contractToAddToVRF
        );
        vm.stopBroadcast();
    }

    function run() external {
        // addConsumerUsingConfig(contractToAddToVRF);
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
