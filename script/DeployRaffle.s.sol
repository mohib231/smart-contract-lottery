//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Integration, FundSubscription, AddConsumer} from "./Integration.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint256 entranceFee,
            uint256 interval,
            address coordinator,
            bytes32 gasLane,
            uint256 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            address account
        ) = helperConfig.activeNetworkConfig();

        require(account != address(0), "Cannot set owner to zero address");

        if (subscriptionId == 0) {
            Integration integration = new Integration();
            (subscriptionId, coordinator) = integration.createSubscription(
                coordinator,
                account
            );
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                coordinator,
                subscriptionId,
                link,
                account
            );
        }

        vm.startBroadcast(account);
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            coordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            coordinator,
            subscriptionId,
            account
        );

        return (raffle, helperConfig);
    }
}
