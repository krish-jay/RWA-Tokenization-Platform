// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ICorporateActions
 * @notice Interface for corporate actions management
 * @dev Handles dividends, redemptions, and other asset-related distributions
 */
interface ICorporateActions {
    // ============ STRUCTS ============
    struct Dividend {
        address token;
        uint256 amountPerToken; // USDC per token (6 decimals)
        uint256 totalAmount;
        uint256 snapshotBlock;
        uint256 claimStart;
        uint256 claimEnd;
        uint256 distributedAmount;
        bool isActive;
    }
    
    struct Redemption {
        address token;
        uint256 redemptionPrice; // USDC per token (6 decimals)
        uint256 totalSupply;
        uint256 redeemedSupply;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
    }
    
    // ============ EVENTS ============
    event DividendDeclared(
        address indexed token,
        uint256 amountPerToken,
        uint256 totalAmount,
        uint256 snapshotBlock,
        uint256 claimStart,
        uint256 claimEnd
    );
    
    event DividendClaimed(
        address indexed investor,
        address indexed token,
        uint256 amount
    );
    
    event RedemptionInitiated(
        address indexed token,
        uint256 redemptionPrice,
        uint256 startTime,
        uint256 endTime
    );
    
    event TokensRedeemed(
        address indexed investor,
        address indexed token,
        uint256 tokenAmount,
        uint256 usdcAmount
    );
    
    event CorporateActionClosed(address indexed token, string actionType);

    // ============ DIVIDEND FUNCTIONS ============
    function declareDividend(
        address token,
        uint256 amountPerToken,
        uint256 claimPeriodDays
    ) external returns (bytes32 dividendId);
    
    function fundDividend(address token, uint256 amount) external;
    function claimDividend(address token) external;
    function batchClaimDividend(address[] calldata tokens) external;
    
    // ============ REDEMPTION FUNCTIONS ============
    function initiateRedemption(
        address token,
        uint256 redemptionPrice,
        uint256 redemptionPeriodDays
    ) external returns (bytes32 redemptionId);
    
    function fundRedemption(address token, uint256 amount) external;
    function redeemTokens(address token, uint256 amount) external;
    function batchRedeemTokens(address[] calldata tokens, uint256[] calldata amounts) external;
    
    // ============ ADMIN FUNCTIONS ============
    function closeDividend(address token) external;
    function closeRedemption(address token) external;
    function emergencyWithdraw(address token) external;
    
    // ============ VIEW FUNCTIONS ============
    function getDividend(address token) external view returns (Dividend memory);
    function getRedemption(address token) external view returns (Redemption memory);
    function getClaimableDividend(address investor, address token) external view returns (uint256);
    function getRedeemableAmount(address investor, address token) external view returns (uint256);
    function hasClaimedDividend(address investor, address token) external view returns (bool);
    function getSnapshotBalance(address investor, address token, uint256 blockNumber) external view returns (uint256);
}