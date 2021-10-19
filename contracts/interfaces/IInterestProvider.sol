// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IInterestProvider {
    function aaveAmount(address[] calldata _markets) external returns (uint256);

    function interestAmount(address _token) external returns (uint256);

    function getCompBalanceMetadataExt(
        address _comp,
        address _comptroller,
        address _holder
    ) external returns (uint256[4] memory);
}
