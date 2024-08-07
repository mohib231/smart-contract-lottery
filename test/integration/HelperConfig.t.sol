//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import "../../script/HelperConfig.s.sol";
import "lib/forge-std/src/Test.sol";

// contract HelperConfigTest is Test {
//     HelperConfig public helperConfig;

//     function run() external {
//         helperConfig = new HelperConfig();
//     }

//     modifier forktest() {
//         if (block.chainid != 31337) {
//             return;
//         }
//         _;
//     }
//     // function test_sepoliaTestNetwork() public forktest {
//     //     HelperConfig.networkConfig memory config = helperConfig
//     //         .getSepoliaEthConfig();

//     //     assertEq(config.entranceFee, 0.1 ether);
//     //     assertEq(config.interval, 30);
//     //     assertEq(
//     //         config.coordinator,
//     //         0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
//     //     );
//     //     assertEq(
//     //         config.gasLane,
//     //         0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
//     //     );
//     //     assertEq(
//     //         config.subscriptionId,
//     //         89893997771484702800239423555426967606568758206275980651178817379072674122430
//     //     );
//     //     assertEq(config.callbackgasLimit, 500000);
//     //     assertEq(config.link, 0x779877A7B0D9E8603169DdbD7836e478b4624789);
//     //     assertEq(config.account, 0x9110ec73cF857483af9BBD9AEe7ade0CebcB98CE);
//     // }
//     function testGetorCreateAnvilWthConfig() public forktest {
//         console.log("Testing Anvil network configuration");

//         HelperConfig.networkConfig memory config = helperConfig
//             .getorCreateAnvilWthConfig();

//         // Validate the configuration
//         assertEq(config.entranceFee, 0.1 ether);
//         assertEq(config.interval, 30);
//         console.log("Coordinator address:", config.coordinator);
//         assertEq(config.coordinator != address(0), true);
//         assertEq(
//             config.gasLane,
//             0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
//         );
//         assertEq(config.subscriptionId, 0);
//         assertEq(config.callbackgasLimit, 2500000);
//         console.log("Link token address:", config.link);
//         assertEq(config.link != address(0), true);
//         assertEq(config.account, 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);

//         console.log("Anvil network configuration passed");
//     }
// }
