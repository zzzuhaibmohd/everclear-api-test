// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract MockEverclearPayment {
    event IntentAdded(bytes32 intentId, uint256 queuePosition, Intent intent);

    uint256 public nonce;
    uint32 public DOMAIN;
    mapping(bytes32 => IntentStatus) public status;

    enum IntentStatus {
        NONE,
        ADDED,
        SETTLED,
        SETTLED_AND_MANUALLY_EXECUTED
    }

    struct Intent {
        address initiator;
        address receiver;
        address inputAsset;
        address outputAsset;
        uint256 amount;
        uint24 maxFee;
        uint32 origin;
        uint32[] destinations;
        uint256 nonce;
        uint48 timestamp;
        uint48 ttl;
        bytes data;
    }

    function newIntent(
        uint32[] memory _destinations,
        address _to,
        address _inputAsset,
        address _outputAsset,
        uint256 _amount,
        uint24 _maxFee,
        uint48 _ttl,
        bytes calldata _data
    ) external returns (bytes32 _intentId, Intent memory _intent) {
        // Increment nonce for each new intent
        nonce++;

        _intent = Intent({
            initiator: msg.sender,
            receiver: _to,
            inputAsset: _inputAsset,
            outputAsset: _outputAsset,
            amount: _amount,
            maxFee: _maxFee,
            origin: DOMAIN,
            destinations: _destinations,
            nonce: nonce,
            timestamp: uint48(block.timestamp),
            ttl: _ttl,
            data: _data
        });

        // Generate a unique intent ID
        _intentId = keccak256(abi.encode(_intent));

        // Set intent status to ADDED and emit the event
        status[_intentId] = IntentStatus.ADDED;
        emit IntentAdded(_intentId, nonce, _intent);

        return (_intentId, _intent);
    }
}
