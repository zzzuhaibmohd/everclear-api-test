// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.23;

import {CrossChainPayment} from "src/CrossChainPayment.sol";
import {IEverclearSpoke} from "src/interfaces/IEverclearSpoke.sol";
import "forge-std/console2.sol";

contract EverclearPayment is CrossChainPayment {
    IEverclearSpoke public everClearSpoke;

    constructor(address _everclearSpoke, address _weth) CrossChainPayment(_weth) {
        everClearSpoke = IEverclearSpoke(_everclearSpoke);
    }

    function _executeBridgeTransfer(PaymentOrder memory order, bytes memory executionData)
        internal
        override
        returns (bytes32 intentId)
    {
        // Decode any additional parameters from executionData
        (uint256 maxFee, uint256 ttl) = abi.decode(executionData, (uint256, uint256));

        // Wrap ETH into WETH to send with the xcall
        weth.deposit{value: msg.value}();

        // This contract approves transfer to EverClearSpoke
        weth.approve(address(everClearSpoke), order.amount);

        // Create destinations array with the target chain
        uint32[] memory destinations = new uint32[](1);
        destinations[0] = order.destinationChainId;

        // Call newIntent on the EverClearSpoke contract
        (bytes32 intentId,) = everClearSpoke.newIntent(
            destinations,
            order.receiver, // to
            order.inputAsset, // inputAsset
            order.outputAsset, // outputAsset (assuming same asset on destination)
            order.amount, // amount
            uint24(maxFee), // maxFee (cast to uint24)
            uint48(ttl), // ttl (cast to uint48)
            "" // empty data field, modify if needed
        );

        return intentId;
    }
}
