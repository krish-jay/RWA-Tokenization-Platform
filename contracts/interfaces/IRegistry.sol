// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IRegistry
 * @notice Interface for asset and investor registry
 * @dev Maintains reference data for the platform
 */
interface IRegistry {
    // ============ STRUCTS ============
    struct Asset {
        bytes32 assetId;
        address token;
        address issuer;
        string name;
        string symbol;
        uint256 totalValue;
        uint256 maxSupply;
        AssetType assetType;
        string jurisdiction;
        uint256 createdAt;
        bool isActive;
    }
    
    struct Investor {
        address wallet;
        bytes32 investorId;
        string jurisdiction;
        InvestorType investorType;
        uint256 kycExpiry;
        bool isActive;
    }
    
    // ============ ENUMS ============
    enum AssetType {
        REAL_ESTATE,
        PRIVATE_CREDIT,
        FUND,
        COMMODITY,
        OTHER
    }
    
    enum InvestorType {
        RETAIL,
        ACCREDITED,
        INSTITUTIONAL
    }

    // ============ EVENTS ============
    event AssetRegistered(
        bytes32 indexed assetId,
        address indexed token,
        address indexed issuer,
        AssetType assetType,
        uint256 maxSupply
    );
    
    event AssetUpdated(
        bytes32 indexed assetId,
        bool isActive
    );
    
    event InvestorRegistered(
        address indexed wallet,
        bytes32 indexed investorId,
        InvestorType investorType,
        string jurisdiction
    );
    
    event InvestorUpdated(
        address indexed wallet,
        bool isActive
    );

    // ============ ASSET MANAGEMENT ============
    function registerAsset(
        bytes32 assetId,
        address token,
        address issuer,
        string calldata name,
        string calldata symbol,
        uint256 totalValue,
        uint256 maxSupply,
        AssetType assetType,
        string calldata jurisdiction
    ) external;
    
    function updateAssetStatus(bytes32 assetId, bool isActive) external;
    function getAsset(bytes32 assetId) external view returns (Asset memory);
    function getAssetByToken(address token) external view returns (Asset memory);
    function isAssetActive(bytes32 assetId) external view returns (bool);
    
    // ============ INVESTOR MANAGEMENT ============
    function registerInvestor(
        address wallet,
        bytes32 investorId,
        InvestorType investorType,
        string calldata jurisdiction,
        uint256 kycExpiry
    ) external;
    
    function updateInvestorStatus(address wallet, bool isActive) external;
    function updateInvestorKYC(address wallet, uint256 newExpiry) external;
    function getInvestor(address wallet) external view returns (Investor memory);
    function isInvestorActive(address wallet) external view returns (bool);
    function getInvestorJurisdiction(address wallet) external view returns (string memory);
    
    // ============ BATCH OPERATIONS ============
    function batchRegisterInvestors(
        address[] calldata wallets,
        bytes32[] calldata investorIds,
        InvestorType[] calldata investorTypes,
        string[] calldata jurisdictions,
        uint256[] calldata kycExpiries
    ) external;
    
    // ============ STATISTICS ============
    function getAssetCount() external view returns (uint256);
    function getInvestorCount() external view returns (uint256);
    function getAssetsByIssuer(address issuer) external view returns (Asset[] memory);
    function getAssetsByType(AssetType assetType) external view returns (Asset[] memory);
}