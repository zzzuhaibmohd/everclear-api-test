// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {EverclearPayment} from "src/EverclearPayment.sol";
import {IWETH} from "src/CrossChainPayment.sol";
import {IEverclearSpoke} from "src/interfaces/IEverclearSpoke.sol";
import {MockEverclearPayment} from "./mocks/MockEverclearPayment.sol";

contract EverclearPaymentTest is Test {
    EverclearPayment public payment; //spoke contract address of source chain
    MockEverclearPayment public EVERCLEAR_SPOKE_MOCK;
    address public constant EVERCLEAR_SPOKE_OPTIMISM = 0xa05A3380889115bf313f1Db9d5f335157Be4D816;

    address public constant RECEIVER = address(0x123);
    uint256 public constant AMOUNT = 1 ether;
    uint32 public constant SOURCE_CHAIN_ID = 10; // Example: Optimism
    uint32 public constant DEST_CHAIN_ID = 8453; // Example: Base

    address public INPUT_ASSET = 0x4200000000000000000000000000000000000006;
    address public OUTPUT_ASSET = 0x4200000000000000000000000000000000000006;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/optimism");
        EVERCLEAR_SPOKE_MOCK = new MockEverclearPayment();
        //payment = new EverclearPayment(EVERCLEAR_SPOKE_OPTIMISM, INPUT_ASSET);
        payment = new EverclearPayment(address(EVERCLEAR_SPOKE_MOCK), INPUT_ASSET);
    }

    function test_CreatePaymentOrder() public returns (uint256) {
        uint256 orderId = payment.createPaymentOrder(AMOUNT, RECEIVER, DEST_CHAIN_ID, INPUT_ASSET, OUTPUT_ASSET);

        // Get the order and verify its details
        EverclearPayment.PaymentOrder memory order = payment.getPaymentOrder(orderId);

        assertEq(order.amount, AMOUNT);
        assertEq(order.sender, address(this));
        assertEq(order.receiver, RECEIVER);
        assertEq(order.destinationChainId, DEST_CHAIN_ID);
        assertEq(order.inputAsset, INPUT_ASSET);
        assertEq(order.outputAsset, OUTPUT_ASSET);

        return orderId;
    }

    function test_MockProcessPayments() public {
        // First create an order
        uint256 orderId = payment.createPaymentOrder(AMOUNT, RECEIVER, DEST_CHAIN_ID, INPUT_ASSET, OUTPUT_ASSET);

        // Process the payment
        uint256 maxFee = 0;
        uint48 ttl = 0;

        vm.deal(address(this), AMOUNT); // Give this contract some ETH
        bytes32 intentId = payment.processPayments{value: AMOUNT}(orderId, maxFee, ttl);

        console2.logBytes32(intentId);
    }

    receive() external payable {}
}
