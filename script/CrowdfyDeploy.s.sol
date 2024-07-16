// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {Crowdfy} from "../src/Crowdfy.sol";

contract CrowdfyDeploy is Script {
    //
    event CrowdfyHasBeenCreated(address indexed crowdfy);
    
    function run() external returns (Crowdfy) {
        vm.startBroadcast();
        Crowdfy crowdfy = new Crowdfy();
        vm.stopBroadcast();

        emit CrowdfyHasBeenCreated(address(crowdfy));
        return crowdfy;
    }
    //
}