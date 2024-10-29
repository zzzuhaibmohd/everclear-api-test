// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.23;

import {IPaymentClientBase} from "./interfaces/IPaymentClientBase.sol";

interface IWETH {
    function deposit() external payable;
    function approve(address guy, uint256 wad) external returns (bool);
}

abstract contract CrossChainPayment is IPaymentClientBase {
    error InvalidReceiver();
    error InvalidChainId();

    IWETH public immutable weth;

    uint256 private nextOrderId;
    mapping(uint256 => PaymentOrder) private paymentOrders;

    event PaymentProcessed(uint256 orderId);

    constructor(address _weth) {
        weth = IWETH(_weth);
    }

    function createPaymentOrder(
        uint256 amount,
        address receiver,
        uint32 destinationChainId,
        address inputAsset,
        address outputAsset
    ) external override returns (uint256 orderId) {
        if (address(receiver) == address(0)) revert InvalidReceiver();
        orderId = nextOrderId++;
        paymentOrders[orderId] = PaymentOrder({
            amount: amount,
            sender: msg.sender,
            receiver: receiver,
            sourceChainId: uint32(block.chainid),
            destinationChainId: destinationChainId,
            inputAsset: inputAsset,
            outputAsset: outputAsset
        });
    }

    // This function should be implemented by the child contract
    function _executeBridgeTransfer(PaymentOrder memory order, bytes memory executionData)
        internal
        virtual
        returns (bytes32 intentId);

    function processPayments(uint256 orderId, uint256 maxFee, uint48 ttl) external payable returns (bytes32 intentId) {
        PaymentOrder memory order = paymentOrders[orderId];
        require(order.sender != address(0), "Invalid order");

        bytes memory executionData = abi.encode(maxFee, ttl);
        // Execute the bridge transfer
        bytes32 intentId = _executeBridgeTransfer(order, executionData);

        emit PaymentProcessed(orderId);
        return intentId;
    }

    function getPaymentOrder(uint256 orderId) external view override returns (PaymentOrder memory) {
        return paymentOrders[orderId];
    }
}
