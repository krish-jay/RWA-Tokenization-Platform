# Data Model & Privacy Boundaries

## 1. On-Chain Data Structures

### 1.1 Core Storage Patterns

**Minimal On-Chain Data Principle**: Store only what's necessary for protocol enforcement

**RWA Token Contract Storage**:
```solidity
// contracts/examples/RWAToken.sol - Storage layout
contract RWAToken is ERC20 {
    // Asset Information
    bytes32 public assetId;          // IPFS hash of asset document
    address public issuer;           // Issuer's MPC wallet
    uint256 public maxSupply;        // Maximum token supply
    Status public status;            // ACTIVE, PAUSED, REDEEMED
    
    // Compliance References
    address public complianceModule; // Compliance module address
    address public registry;         // Registry contract address
    
    // Administrative State
    bool public transfersPaused;     // Global pause state
    mapping(address => bool) public frozen; // Per-address freeze
    
    // Snapshot Support
    mapping(uint256 => mapping(address => uint256)) private _snapshotBalances;
    uint256[] private _snapshotIds;
    
    // Events (indexed for The Graph)
    event TransferWithCompliance(
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes32 complianceCheckId
    );
}

```
Compliance Module Storage:

```solidity

contract ComplianceModule {
    // Allowlist storage (minimal)
    struct InvestorStatus {
        bool isAllowed;
        uint8 investorType;      // 0=not verified, 1=retail, 2=accredited, 3=institutional
        uint16 jurisdictionCode; // Encoded ISO country code
        uint40 kycExpiry;        // Unix timestamp (fits in 40 bits)
    }

    mapping(address => InvestorStatus) public investorStatus;

    // Rule storage
    struct Rule {
        bytes32 ruleId;
        RuleType ruleType;
        bytes conditions;        // Encoded rule parameters
        bool isActive;
        uint40 createdAt;
    }

    mapping(bytes32 => Rule) public rules;
    mapping(address => bytes32[]) public assetRules; // Rules per asset
}

```

### 1.2 On-Chain Data Categories

Publicly Accessible Data:

```text

✅ Token balances (by address)
✅ Total supply and max supply
✅ Contract addresses (token, compliance, issuance)
✅ Allowlist status (boolean only)
✅ Contract status (active, paused, redeemed)
✅ Transaction history (transfers, mints, burns)
✅ Event logs (compliance checks, corporate actions)
```

Admin-Only Data:

```text

⚠️ Investor jurisdiction codes (encoded)
⚠️ Investor type classifications
⚠️ Compliance rule configurations
⚠️ Freeze/pause state per address
⚠️ Upgrade timelock schedules
```

Never Stored On-Chain:

```text

❌ Personal Identifiable Information (PII)
❌ Email addresses
❌ Physical addresses
❌ Government ID numbers
❌ Financial account details
❌ Accreditation documents
❌ Legal agreement content

```

2\. Off-Chain Database Schema
-----------------------------

### 2.1 PostgreSQL Database Design

Core Tables:

```sql

-- issuers table
CREATE TABLE issuers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legal_name VARCHAR(255) NOT NULL,
    business_registration_number VARCHAR(50) UNIQUE,
    jurisdiction VARCHAR(2) NOT NULL, -- ISO 3166-1 alpha-2
    kyc_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    kyc_provider_reference VARCHAR(100),
    wallet_address VARCHAR(42) UNIQUE NOT NULL,
    mpc_custody_provider VARCHAR(50), -- 'fireblocks', 'copper', etc.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    verified_at TIMESTAMPTZ,

    CONSTRAINT check_kyc_status CHECK (kyc_status IN (
        'pending', 'approved', 'rejected', 'suspended'
    ))
);

-- assets table
CREATE TABLE assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issuer_id UUID NOT NULL REFERENCES issuers(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    asset_type VARCHAR(50) NOT NULL,
    total_value DECIMAL(20,2) NOT NULL,
    valuation_currency VARCHAR(3) DEFAULT 'USD',
    token_address VARCHAR(42) UNIQUE NOT NULL,
    token_symbol VARCHAR(10) NOT NULL,
    total_supply DECIMAL(20,2) NOT NULL,
    max_supply DECIMAL(20,2) NOT NULL,
    legal_structure VARCHAR(50), -- 'SPV', 'REIT', 'Fund'
    jurisdiction VARCHAR(2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    ipfs_document_hash VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT check_asset_type CHECK (asset_type IN (
        'real_estate', 'private_credit', 'fund', 'commodity', 'other'
    )),
    CONSTRAINT check_status CHECK (status IN (
        'draft', 'pending_approval', 'active', 'paused', 'redeemed', 'archived'
    ))
);

-- investors table (NO PII)
CREATE TABLE investors (
    wallet_address VARCHAR(42) PRIMARY KEY,
    investor_id_hash VARCHAR(64) UNIQUE, -- SHA256 hash of external investor ID
    kyc_provider VARCHAR(50), -- 'sumsub', 'onfido', etc.
    kyc_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    investor_type VARCHAR(20) NOT NULL DEFAULT 'retail',
    jurisdiction VARCHAR(2),
    accreditation_status VARCHAR(20),
    allowlist_status BOOLEAN NOT NULL DEFAULT FALSE,
    kyc_expiry_date TIMESTAMPTZ,
    risk_level VARCHAR(20) DEFAULT 'medium',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_kyc_check TIMESTAMPTZ,

    CONSTRAINT check_investor_type CHECK (investor_type IN (
        'retail', 'accredited', 'institutional'
    )),
    CONSTRAINT check_kyc_status CHECK (kyc_status IN (
        'pending', 'verified', 'rejected', 'expired'
    ))
);

-- token_holdings table (off-chain mirror)
CREATE TABLE token_holdings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_address VARCHAR(42) NOT NULL REFERENCES investors(wallet_address),
    token_address VARCHAR(42) NOT NULL REFERENCES assets(token_address),
    balance DECIMAL(20,2) NOT NULL DEFAULT 0,
    balance_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_sync_block BIGINT NOT NULL,
    is_frozen BOOLEAN NOT NULL DEFAULT FALSE,

    UNIQUE(wallet_address, token_address)
);

-- corporate_actions table
CREATE TABLE corporate_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES assets(id),
    action_type VARCHAR(20) NOT NULL,
    amount_per_token DECIMAL(20,6) NOT NULL,
    total_amount DECIMAL(20,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    snapshot_block BIGINT NOT NULL,
    claim_start_date TIMESTAMPTZ NOT NULL,
    claim_end_date TIMESTAMPTZ NOT NULL,
    distribution_tx_hash VARCHAR(66),
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT check_action_type CHECK (action_type IN (
        'dividend', 'coupon', 'redemption', 'distribution'
    )),
    CONSTRAINT check_status CHECK (status IN (
        'scheduled', 'active', 'completed', 'cancelled'
    ))
);

-- transactions ledger (off-chain record)
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_hash VARCHAR(66) UNIQUE NOT NULL,
    wallet_address VARCHAR(42) NOT NULL REFERENCES investors(wallet_address),
    token_address VARCHAR(42) NOT NULL REFERENCES assets(token_address),
    transaction_type VARCHAR(20) NOT NULL,
    amount DECIMAL(20,6) NOT NULL,
    usdc_amount DECIMAL(20,2),
    from_address VARCHAR(42),
    to_address VARCHAR(42),
    block_number BIGINT NOT NULL,
    block_timestamp TIMESTAMPTZ NOT NULL,
    gas_used DECIMAL(18,0),
    gas_price DECIMAL(18,0),
    status VARCHAR(20) NOT NULL DEFAULT 'confirmed',
    compliance_check_id VARCHAR(66),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT check_transaction_type CHECK (transaction_type IN (
        'mint', 'burn', 'transfer', 'dividend', 'redemption', 'fee'
    )),
    CONSTRAINT check_status CHECK (status IN (
        'pending', 'confirmed', 'failed', 'reverted'
    ))
);

-- compliance_checks table
CREATE TABLE compliance_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_id VARCHAR(66) UNIQUE NOT NULL,
    transaction_hash VARCHAR(66) REFERENCES transactions(transaction_hash),
    from_address VARCHAR(42) NOT NULL,
    to_address VARCHAR(42) NOT NULL,
    token_address VARCHAR(42) NOT NULL,
    amount DECIMAL(20,6) NOT NULL,
    rule_results JSONB NOT NULL, -- Array of rule validations
    overall_result VARCHAR(10) NOT NULL,
    failure_reason TEXT,
    checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT check_overall_result CHECK (overall_result IN (
        'approved', 'rejected'
    ))
);
```

### 2.2 Indexing Strategy

Critical Indexes:

```sql

-- Performance indexes
CREATE INDEX idx_investors_allowlist ON investors(allowlist_status, jurisdiction);
CREATE INDEX idx_token_holdings_balance ON token_holdings(token_address, balance DESC);
CREATE INDEX idx_transactions_wallet ON transactions(wallet_address, block_timestamp DESC);
CREATE INDEX idx_transactions_token ON transactions(token_address, block_timestamp DESC);
CREATE INDEX idx_corporate_actions_asset ON corporate_actions(asset_id, claim_end_date DESC);

-- Composite indexes for common queries
CREATE INDEX idx_investors_kyc_status ON investors(kyc_status, investor_type, jurisdiction);
CREATE INDEX idx_assets_status ON assets(status, asset_type, jurisdiction);
```

3\. Privacy-First Architecture
------------------------------

### 3.1 Data Flow with Privacy Boundaries

```text

Investor Registration Flow:
1. Investor submits KYC documents → KYC Provider (off-chain)
2. KYC Provider returns verification result → Platform Backend
3. Platform stores: verification status + metadata hash → Database
4. Platform calls: addToAllowlist(wallet, encoded_jurisdiction, investor_type) → Blockchain
5. Original documents encrypted → Secure Storage (AWS S3 + KMS)
```

### 3.2 Encryption Strategy

At Rest Encryption:

-   Database: PostgreSQL native encryption + column-level encryption for sensitive fields

-   Document Storage: AES-256-GCM with KMS-managed keys

-   Backups: Encrypted with separate backup keys

In Transit Encryption:

-   All APIs: TLS 1.3

-   WebSocket connections: WSS with message-level encryption

-   Blockchain RPC: TLS where supported, otherwise VPN tunnels


### 4.2 Event Handlers

```typescript

// mappings.ts
export function handleTransferWithCompliance(event: TransferWithCompliance): void {
  // Create Transfer entity
  let transferId = event.transaction.hash.toHex() + '-' + event.logIndex.toString();
  let transfer = new Transfer(transferId);

  transfer.asset = event.address.toHex();
  transfer.from = event.params.from;
  transfer.to = event.params.to;
  transfer.amount = event.params.amount;
  transfer.blockNumber = event.block.number;
  transfer.blockTimestamp = event.block.timestamp;
  transfer.transactionHash = event.transaction.hash;

  // Update holder balances
  updateHolderBalance(event.address, event.params.from, event.block.number, false);
  updateHolderBalance(event.address, event.params.to, event.block.number, true);

  transfer.save();
}
```
5\. Reconciliation System
-------------------------

### 5.1 Daily Reconciliation Process

Process Flow:

```text

1\. For each asset token:
   a. Query on-chain total supply
   b. Sum off-chain token_holdings.balance
   c. Compare: must match within tolerance (0.001%)

2. For each investor:
   a. Query on-chain token balance
   b. Compare with off-chain token_holdings.balance
   c. Flag discrepancies > 0.01 tokens

3. For each corporate action:
   a. Verify on-chain distributed amount matches off-chain records
   b. Check claim counts match

4. Generate reconciliation report:
   - Matches: 99.9% expected
   - Minor discrepancies: Manual review
   - Major discrepancies: Immediate alert
```

### 5.2 Reconciliation Queries

```sql

-- Daily reconciliation query
WITH onchain_balances AS (
    SELECT
        token_address,
        SUM(balance_onchain) as total_onchain
    FROM (
        -- This would be filled by querying blockchain via RPC
        SELECT '0x1234...' as token_address, 1000.00 as balance_onchain
        UNION ALL
        SELECT '0x1234...' as token_address, 500.00 as balance_onchain
    ) balances
    GROUP BY token_address
),
offchain_balances AS (
    SELECT
        token_address,
        SUM(balance) as total_offchain
    FROM token_holdings
    WHERE balance_updated_at > NOW() - INTERVAL '24 hours'
    GROUP BY token_address
)
SELECT
    COALESCE(o.token_address, f.token_address) as token_address,
    COALESCE(o.total_onchain, 0) as onchain_total,
    COALESCE(f.total_offchain, 0) as offchain_total,
    ABS(COALESCE(o.total_onchain, 0) - COALESCE(f.total_offchain, 0)) as discrepancy,
    CASE
        WHEN ABS(COALESCE(o.total_onchain, 0) - COALESCE(f.total_offchain, 0)) > 0.001
        THEN 'ALERT'
        ELSE 'OK'
    END as status
FROM onchain_balances o
FULL OUTER JOIN offchain_balances f ON o.token_address = f.token_address;
```

6\. Data Export for Regulatory Reporting
----------------------------------------

### 6.1 Required Reports

Daily Reports:

-   Token holder register (per asset)

-   Transaction ledger (all transfers)

-   Compliance violation log

-   Corporate action distributions

Monthly Reports:

-   Asset valuation updates

-   Investor activity summary

-   Treasury balances and movements

-   Compliance rule effectiveness

Annual Reports:

-   Tax reporting (Form 1099 equivalent)

-   Audit trail completeness

-   System security assessment

-   Regulatory compliance attestation

### 6.2 Report Generation Queries

```sql

-- Monthly investor activity report
SELECT
    i.wallet_address,
    i.investor_type,
    i.jurisdiction,
    COUNT(DISTINCT t.token_address) as assets_held,
    SUM(CASE WHEN t.transaction_type = 'transfer' THEN 1 ELSE 0 END) as transfer_count,
    SUM(CASE WHEN t.transaction_type = 'dividend' THEN t.usdc_amount ELSE 0 END) as dividends_received,
    MIN(t.block_timestamp) as first_activity,
    MAX(t.block_timestamp) as last_activity
FROM investors i
LEFT JOIN transactions t ON i.wallet_address = t.wallet_address
WHERE t.block_timestamp >= DATE_TRUNC('month', NOW() - INTERVAL '1 month')
  AND t.block_timestamp < DATE_TRUNC('month', NOW())
GROUP BY i.wallet_address, i.investor_type, i.jurisdiction
ORDER BY dividends_received DESC;
```

7\. Backup and Disaster Recovery
--------------------------------

### 7.1 Backup Strategy

Real-time Backup:

-   Blockchain: Event streaming to backup cluster

-   Database: Continuous WAL archiving to S3

-   Documents: Real-time replication to secondary region

Scheduled Backups:

-   Database: Daily full backup + hourly incremental

-   Configuration: Version-controlled in Git

-   Keys: Encrypted backup to offline storage

### 7.2 Recovery Procedures

Database Recovery:

1.  Restore latest WAL backup

2.  Replay blockchain events from last checkpoint

3.  Verify data consistency with on-chain state

4.  Switch traffic to recovered database

Blockchain Event Recovery:

1.  Re-index from last confirmed block

2.  Replay all events through The Graph

3.  Verify subgraph data matches contract state

4.  Update off-chain database from subgraph

This data model ensures regulatory compliance, operational efficiency, and investor privacy while maintaining the transparency benefits of blockchain technology.