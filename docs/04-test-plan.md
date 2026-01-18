# Test & Verification Plan

## 1. Testing Strategy Overview

### 1.1 Testing Pyramid

```text

      ┌─────────────────┐
      │   E2E Tests     │  (10%)
      │  (Integration)  │
      └─────────┬───────┘
                │
      ┌─────────▼───────┐
      │  API/Contract   │  (20%)
      │  Integration    │
      └─────────┬───────┘
                │
      ┌─────────▼───────┐
      │   Unit Tests    │  (70%)
      │  (Foundation)   │
      └─────────────────┘

```

### 1.2 Test Coverage Goals

```text

| Component            | Target Coverage | Critical Paths                                                |
|----------------------|-----------------|---------------------------------------------------------------|
| RWA Token Contract   | 95%             | Transfers, minting, burning, compliance hooks                 |
| Compliance Module    | 100%            | Allowlist, jurisdiction, investor type checks                 |
| Issuance Module      | 90%             | Primary sales, escrow, subscription flows                     |
| Corporate Actions    | 85%             | Dividend distribution, redemptions                            |
| Registry             | 80%             | Asset/investor registration, updates                          |
| Proxy / Upgrade      | 100%            | Upgrade safety, storage preservation                          |


```

## 2. Test Scenarios Matrix

### 2.1 Happy Path Scenarios

```text

| Scenario                  | Description                     | Success Criteria                           |
|---------------------------|---------------------------------|--------------------------------------------|
| H1: Asset Issuance        | Issuer creates new token        | Token deployed, max supply set             |
| H2: Investor Onboarding   | Investor completes KYC          | Added to allowlist                         |
| H3: Primary Purchase      | Investor buys in primary        | Tokens minted, payment settled             |
| H4: Secondary Transfer    | Investor sells to another       | Tokens transferred, compliance checked     |
| H5: Dividend Distribution | Issuer distributes income       | Investors receive pro-rata share           |
| H6: Redemption            | Asset sold, tokens redeemed     | Investors receive proceeds                 |

```

### 2.2 Edge Case Scenarios

```text

| Scenario                        | Description                         | Expected Behavior        |
|---------------------------------|-------------------------------------|--------------------------|
| E1: Transfer to non-allowlisted | Send to unverified address          | Revert with error        |
| E2: Jurisdiction violation      | Cross-border restriction            | Revert with error        |
| E3: Investor type mismatch      | Retail tries to buy accredited-only | Revert with error        |
| E4: Transfer when paused        | Global pause active                 | Revert with error        |
| E5: Frozen account              | Address frozen by admin             | Revert with error        |
| E6: Exceed max supply           | Mint beyond limit                   | Revert with error        |
| E7: Claim expired dividend      | After claim period                  | Revert with error        |
| E8: Insufficient redemption funds | Not enough USDC in pool           | Revert with error        |

```

### 2.3 Failure Mode Scenarios

```text

| Scenario                   | Description               | Recovery Mechanism                |
|----------------------------|---------------------------|-----------------------------------|
| F1: Compliance module down | Contract reverts          | Emergency bypass mode             |
| F2: Oracle stale price     | Old NAV data              | Manual override by admin          |
| F3: Gas price spike        | Operations too expensive  | Schedule for off-peak             |
| F4: Frontend compromised   | Phishing attack           | Transaction simulation warnings   |
| F5: Database corruption    | Off-chain data lost       | Rebuild from blockchain           |

```
