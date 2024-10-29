// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IPaymentClientBase {
    struct PaymentOrder {
        uint256 amount;
        address sender;
        address receiver;
        uint32 sourceChainId;
        uint32 destinationChainId;
        address inputAsset;
        address outputAsset;
    }

    function createPaymentOrder(
        uint256 amount,
        address receiver,
        uint32 destinationChainId,
        address inputAsset,
        address outputAsset
    ) external returns (uint256 orderId);

    function getPaymentOrder(uint256 orderId) external view returns (PaymentOrder memory);
}
