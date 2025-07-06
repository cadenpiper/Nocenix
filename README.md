## 👋 Welcome to the Nocenix Project!

This project implements the `Nocenix` fungible token on the Flow Blockchain, featuring no token initial supply, max supply of one billion tokens, and metadata for wallet/marketplace display. It includes contracts, scripts, transactions, and a configuration to help you get started.

## 🔨 Getting Started

Essential resources for developing on Flow:

- **[Flow Documentation](https://developers.flow.com/)** - Learn about [building](https://developers.flow.com/build/flow) on Flow.
- **[Flow CLI](https://developers.flow.com/tools/flow-cli)** - Flow CLI docs
- **[Cadence Documentation](https://cadence-lang.org/docs/language)** - Understand Cadence, Flow’s resource-oriented smart contract language.
- **[Visual Studio Code](https://code.visualstudio.com/)** and **[Cadence Extension](https://marketplace.visualstudio.com/items?itemName=onflow.cadence)** - Use VSCode with the Cadence extension for syntax highlighting and code completion.
- **[Flow Clients](https://developers.flow.com/tools/clients)** - Interact with your smart contracts using Flow clients.
- **[Block Explorers](https://developers.flow.com/ecosystem/block-explorers)** - Use [Flowser](https://flowser.dev/) for local emulator development.

## 📦 Project Structure

The project is structured as follows:

- `flow.json` - Configuration file defining contract deployments and dependencies, including `FungibleToken`, `MetadataViews`, `FungibleTokenMetadataViews`, and `Nocenix`.

Dependencies configured in `flow.json`:
- `FungibleToken`
- `MetadataViews`
- `FungibleTokenMetadataViews`

Add more dependencies with `flow deps add`.

- `/cadence` - Contains all Cadence code:
  - `/contracts` - Smart contracts:
    - `Nocenix.cdc` - Defines the `Nocenix` fungible token with no initial supply, metadata (name, symbol, logo, socials), and admin controls.
  - `/scripts` - Read-only operations:
    - `GetNocenixBalance.cdc` - Retrieves user vault balance, and contract vault total supply.
    - `GetTokenMetadata.cdc` - Retrieves token metadata (name, symbol, description, logo, socials).
  - `/transactions` - State-changing operations:
    - `Mint.cdc` - Mints tokens to a recipient’s vault.
    - `Burn.cdc` - Burns tokens from a user's vault.
  - `/tests` - Placeholder for tests (currently empty):
    - Add tests to verify contract, script, and transaction behavior.

## 🚀 Run Project (Emulator Setup)

✅ Step 1: Start the Flow Emulator
```
flow emulator
```


📦 Step 2: Deploy the Contract
```
flow project deploy --network emulator
```


📋 Step 3: Check Token Metadata
```
flow scripts execute cadence/scripts/GetTokenMetadata.cdc <emulator-account-address> --network emulator
```
Replace emulator-account-address with the address that deployed the contract. You can find this address in the flow.json file under accounts.


👤 Step 4: Create a Recipient Account
```
flow accounts create
```
This will generate a new account in the flow.json file.


💸 Step 5: Mint and Transfer Tokens
```
flow transactions send cadence/transactions/Mint.cdc 100.0 <recipient-account-address>
  --authorizer emulator-account,recipient-account
  --proposer recipient-account
  --payer emulator-account
  --network emulator
```
Mints 100 tokens. Replace recipient-account-address with the address under the recipient account in flow.json.


🔥Step 6: Burn Tokens
```
flow transactions send cadence/transactions/Burn.cdc 50.0 --signer <recipient-account-address> --network emulator
```
Burns 50 tokens.


📊 Step 7: Check Balances
```
flow scripts execute cadence/scripts/GetNocenixBalance.cdc <emulator-account-address> <recipient-account-address> --network emulator
```
This verifies the token balance of the recipient of the Mint transaction.
