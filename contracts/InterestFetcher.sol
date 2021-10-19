// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IInterestProvider.sol";
import "./BasicAMBInformationReceiver.sol";

contract InterestFetcher is BasicAMBInformationReceiver, Ownable {
    uint256 public lastFetchTime;
    uint256 public minFetchInterval;

    struct Job {
        address holder;
        address target;
        address token;
        bytes data;
        uint256 resultOffset;
    }

    struct JobMetadata {
        address holder;
        address token;
        uint256 timestamp;
        uint256 resultOffset;
    }

    Job[] private jobs;
    mapping(bytes32 => JobMetadata) private jobMetadata;
    mapping(address => mapping(address => uint256)) private lastJobTime;

    event InterestFetched(address indexed holder, address indexed token, uint256 timestamp, uint256 interest);

    constructor(IHomeAMB _bridge, uint256 _minFetchInterval) AMBInformationReceiverStorage(_bridge) {
        {
            address xdaiBridge = address(0x4aa42145Aa6Ebf72e164C9bBC74fbD3788045016);
            address compLens = address(0xA1Bd4a10185F30932C78185f86641f11902E873F);
            address comptroller = address(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
            address daiToken = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
            address compToken = address(0xc00e94Cb662C3520282E6f5717214004A7f26888);
            jobs.push(
                Job(
                    xdaiBridge,
                    xdaiBridge,
                    daiToken,
                    abi.encodeWithSelector(IInterestProvider.interestAmount.selector, daiToken),
                    0
                )
            );
            jobs.push(
                Job(
                    xdaiBridge,
                    compLens,
                    compToken,
                    abi.encodeWithSelector(
                        IInterestProvider.getCompBalanceMetadataExt.selector,
                        compToken,
                        comptroller,
                        xdaiBridge
                    ),
                    96
                )
            );
        }

        {
            address omnibridge = address(0x88ad09518695c6c3712AC10a214bE5109a655671);
            address aaveInterest = address(0x87D48c565D0D85770406D248efd7dc3cbd41e729);
            address usdcToken = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
            address usdtToken = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
            address aaveToken = address(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
            address[] memory aTokens = new address[](2);
            aTokens[0] = address(0xBcca60bB61934080951369a648Fb03DF4F96263C);
            aTokens[1] = address(0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811);
            jobs.push(
                Job(
                    omnibridge,
                    aaveInterest,
                    usdcToken,
                    abi.encodeWithSelector(IInterestProvider.interestAmount.selector, usdcToken),
                    0
                )
            );
            jobs.push(
                Job(
                    omnibridge,
                    aaveInterest,
                    usdtToken,
                    abi.encodeWithSelector(IInterestProvider.interestAmount.selector, usdtToken),
                    0
                )
            );
            jobs.push(
                Job(
                    omnibridge,
                    aaveInterest,
                    aaveToken,
                    abi.encodeWithSelector(IInterestProvider.aaveAmount.selector, aTokens),
                    0
                )
            );
        }

        minFetchInterval = _minFetchInterval;
    }

    function fetchInterest() external {
        require(lastFetchTime + minFetchInterval < block.timestamp);
        lastFetchTime = block.timestamp;

        for (uint256 i = 0; i < jobs.length; i++) {
            _execJob(jobs[i]);
        }
    }

    function allJobs() external view returns (Job[] memory) {
        return jobs;
    }

    function removeJob(uint256 i) external onlyOwner {
        require(i < jobs.length, "Invalid job index");
        if (i < jobs.length - 1) {
            jobs[i] = jobs[jobs.length - 1];
        }
        jobs.pop();
    }

    function addJob(Job calldata job) external onlyOwner {
        jobs.push(job);
    }

    function setMinFetchInterval(uint256 interval) external onlyOwner {
        minFetchInterval = interval;
    }

    function killMe() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function _execJob(Job storage job) internal {
        bytes memory data = abi.encode(job.target, job.data);
        bytes32 selector = keccak256("eth_call(address,bytes)");
        bytes32 messageId = bridge.requireToGetInformation(selector, data);
        _setStatus(messageId, Status.Pending);
        jobMetadata[messageId] = JobMetadata(job.holder, job.token, block.timestamp, job.resultOffset);
    }

    function _unwrap(bytes memory _result) internal pure returns (bytes memory) {
        return abi.decode(_result, (bytes));
    }

    function onResultReceived(bytes32 _messageId, bytes memory _result) internal override {
        bytes memory unwrapped = _unwrap(_result);
        JobMetadata memory md = jobMetadata[_messageId];
        // getCompBalanceMetadataExt, first slot ?
        require(unwrapped.length >= md.resultOffset + 32, "Invalid result length");
        uint256 interest;
        uint256 offset = md.resultOffset;
        assembly {
            interest := mload(add(unwrapped, add(32, offset)))
        }
        delete jobMetadata[_messageId];
        if (lastJobTime[md.holder][md.token] < md.timestamp) {
            lastJobTime[md.holder][md.token] = md.timestamp;
            emit InterestFetched(md.holder, md.token, md.timestamp, interest);
        }
    }
}
