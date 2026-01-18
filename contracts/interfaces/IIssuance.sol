// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IIssuance
 * @notice Interface for primary market issuance and sales
 * @dev Handles initial token offerings and subscription flows
 */
interface IIssuance {
    // ============ STRUCTS ============
    struct Offering {
        address token;
        address issuer;
        uint256 price; // Price per token in USDC (6 decimals)
        uint256 maxSupply;
        uint256 soldSupply;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isFullySubscribed;
    }
    
    struct Subscription {
        address investor;
        uint256 amount; // Token amount requested
        uint256 amountPaid; // USDC paid
        bool isApproved;
        bool isFulfilled;
        uint256 requestedAt;
        uint256 approvedAt;
    }
    
    // ============ ENUMS ============
    enum OfferingType {
        FIXED_PRICE,
        SUBSCRIPTION
    }

    // ============ EVENTS ============
    event OfferingCreated(
        address indexed token,
        address indexed issuer,
        uint256 price,
        uint256 maxSupply,
        uint256 startTime,
        uint256 endTime,
        OfferingType offeringType
    );
    
    event SubscriptionRequested(
        address indexed token,
        address indexed investor,
        uint256 amount,
        uint256 amountPaid
    );
    
    event SubscriptionApproved(
        address indexed token,
        address indexed investor,
        uint256 amount
    );
    
    event TokensIssued(
        address indexed token,
        address indexed investor,
        uint256 amount,
        uint256 price
    );
    
    event OfferingClosed(address indexed token, uint256 totalSold);

    // ============ OFFERING MANAGEMENT ============
    function createOffering(
        address token,
        uint256 price,
        uint256 maxSupply,
        uint256 startTime,
        uint256 endTime,
        OfferingType offeringType
    ) external returns (bytes32 offeringId);
    
    function closeOffering(address token) external;
    
    // ============ INVESTOR FUNCTIONS ============
    function subscribe(
        address token,
        uint256 amount
    ) external returns (bytes32 subscriptionId);
    
    function approveSubscription(
        address token,
        address investor,
        bool approve
    ) external;
    
    function claimTokens(address token) external;
    
    // ============ PAYMENT HANDLING ============
    function withdrawProceeds(address token) external;
    function refundSubscription(address token, address investor) external;
    
    // ============ VIEW FUNCTIONS ============
    function getOffering(address token) external view returns (Offering memory);
    function getSubscription(address token, address investor) external view returns (Subscription memory);
    function getOfferingBalance(address token) external view returns (uint256);
    function isOfferingActive(address token) external view returns (bool);
    function getAvailableTokens(address token) external view returns (uint256);
}