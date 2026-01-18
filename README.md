# RWA Tokenization Platform - Technical Design Submission

## Overview
A production-ready architecture for Real-World Asset (RWA) tokenization with on-chain compliance enforcement, designed for security, scalability, and regulatory compliance.

## Key Design Decisions
- **Token Standard**: ERC-20 with compliance hooks (ERC-1400 inspired)
- **Chain**: Ethereum mainnet (EVM-compatible)
- **Compliance**: On-chain enforcement with off-chain verification
- **Custody**: Hybrid model (Issuer: MPC, Investor: Self-custody)
- **Payment**: USDC on-chain + fiat rails off-chain
- **Upgradeability**: Transparent Proxy Pattern with timelock

## Navigation Guide
- **Architecture Document**: `docs/01-architecture.md` (comprehensive design)
- **Sequence Diagrams**: `docs/02-sequence-diagrams.md` (key user flows)
- **Data Model**: `docs/03-data-model.md` (on-chain/off-chain boundaries)
- **Test Plan**: `docs/04-test-plan.md` (verification strategy)
- **Risk Register**: `docs/05-risk-register.md` (risk mitigations)
- **Smart Contracts**: `contracts/interfaces/` (core interfaces)
- **Diagrams**: `diagrams/` (Mermaid source files)

## Assumptions (Stated Clearly)
1. Single EVM chain deployment initially (Ethereum mainnet)
2. US-focused with accredited investor requirements (extensible globally)
3. Real estate as primary asset class (modular for others)
4. Platform acts as regulated transfer agent
5. Legal structures (SPVs) established off-chain
6. No PII on-chain (only allowlist status and encoded attributes)

## How to Review
1. Start with architecture overview for big picture
2. Examine sequence diagrams for key user flows
3. Review smart contract interfaces for implementation details
4. Check security considerations and risk mitigations
5. View diagrams in `/diagrams/` for visual understanding

## Quick Start
To view diagrams:
```bash
# Install Mermaid CLI (optional)
npm install -g @mermaid-js/mermaid-cli

# Generate diagrams from source
mmdc -i diagrams/architecture.mmd -o diagrams/architecture.png