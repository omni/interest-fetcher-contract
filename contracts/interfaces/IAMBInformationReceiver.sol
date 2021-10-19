// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IAMBInformationReceiver {
    function onInformationReceived(
        bytes32 messageId,
        bool status,
        bytes calldata result
    ) external;
}
