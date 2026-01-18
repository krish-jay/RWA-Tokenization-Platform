// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IRWAToken
 * @notice Interface for RWA Token with compliance hooks
 * @dev Extends ERC-20 with transfer restrictions and administrative controls
 */
interface IRWAToken is IERC20 {
    // ============ ENUMS ============
    enum Status {
        ACTIVE,
        PAUSED,
        FROZEN,
        REDEEMED
    }
    
    enum InvestorType {
        NOT_VERIFIED,
        RETAIL,
        ACCREDITED,
        INSTITUTIONAL
    }

    // ============ EVENTS ============
    event TransferWithCompliance(
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes32 complianceCheckId
    );
    
    event AllowlistUpdated(
        address indexed investor,
        bool isAllowed,
        uint256 jurisdictionCode,
        InvestorType investorType
    );
    
    event StatusChanged(
        Status oldStatus,
        Status newStatus
    );
    
    event AddressFrozen(address indexed account);
    event AddressUnfrozen(address indexed account);

    // ============ ADMIN FUNCTIONS ============
    function pause() external;
    function unpause() external;
    function freezeAddress(address account) external;
    function unfreezeAddress(address account) external;
    function forceTransfer(address from, address to, uint256 amount) external;
    
    // ============ ISSUANCE FUNCTIONS ============
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
    
    // ============ COMPLIANCE FUNCTIONS ============
    function addToAllowlist(
        address investor,
        uint256 jurisdictionCode,
        InvestorType investorType
    ) external;
    
    function removeFromAllowlist(address investor) external;
    function isAllowlisted(address account) external view returns (bool);
    function getInvestorInfo(address account) external view returns (
        bool allowed,
        uint256 jurisdictionCode,
        InvestorType investorType,
        uint256 lastKycCheck
    );
    
    // ============ VIEW FUNCTIONS ============
    function getStatus() external view returns (Status);
    function isFrozen(address account) external view returns (bool);
    function maxSupply() external view returns (uint256);
    function assetId() external view returns (bytes32);
}