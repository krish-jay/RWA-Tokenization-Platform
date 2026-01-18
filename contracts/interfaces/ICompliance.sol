// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ICompliance
 * @notice Interface for the compliance validation module
 * @dev Centralized compliance checking with configurable rules
 */
interface ICompliance {
    // ============ STRUCTS ============
    struct Rule {
        bytes32 ruleId;
        RuleType ruleType;
        bytes conditions;
        bool isActive;
    }
    
    struct ValidationResult {
        bool isValid;
        bytes32[] passedRules;
        bytes32[] failedRules;
        string failureReason;
    }
    
    enum RuleType {
        ALLOWLIST,
        JURISDICTION,
        INVESTOR_TYPE,
        TRANSFER_LIMIT,
        TIME_LOCK
    }
    
    // ============ EVENTS ============
    event RuleAdded(bytes32 indexed ruleId, RuleType ruleType);
    event RuleUpdated(bytes32 indexed ruleId, bool isActive);
    event RuleRemoved(bytes32 indexed ruleId);
    event ValidationPerformed(
        bytes32 indexed checkId,
        address indexed token,
        address from,
        address to,
        uint256 amount,
        bool approved
    );

    // ============ ADMIN FUNCTIONS ============
    function addRule(Rule memory rule) external returns (bytes32);
    function updateRule(bytes32 ruleId, bool isActive) external;
    function removeRule(bytes32 ruleId) external;
    
    // ============ VALIDATION FUNCTIONS ============
    function validateTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) external returns (ValidationResult memory);
    
    function canTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) external view returns (bool);
    
    // ============ BATCH OPERATIONS ============
    function batchAddToAllowlist(
        address token,
        address[] calldata investors,
        uint256[] calldata jurisdictionCodes,
        uint8[] calldata investorTypes
    ) external;
    
    function batchRemoveFromAllowlist(
        address token,
        address[] calldata investors
    ) external;
    
    // ============ VIEW FUNCTIONS ============
    function getRule(bytes32 ruleId) external view returns (Rule memory);
    function getActiveRules(address token) external view returns (Rule[] memory);
    function isAddressFrozen(address token, address account) external view returns (bool);
    function getJurisdictionCode(address account) external view returns (uint256);
}