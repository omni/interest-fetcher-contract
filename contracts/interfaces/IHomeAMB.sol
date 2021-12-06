// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IHomeAMB {
    function messageId() external view returns (bytes32);

    function requireToGetInformation(bytes32 _requestSelector, bytes calldata _data) external returns (bytes32);
}
