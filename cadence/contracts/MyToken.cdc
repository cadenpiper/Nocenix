import FungibleToken from "FungibleToken"

access(all) contract MyToken: FungibleToken {
    // Total supply of tokens
    access(all) var totalSupply: UFix64

    // Storage and public paths
    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultPublicPath: PublicPath
    access(all) let ReceiverPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath

    // Events (update TokensMinted to include recipient)
    access(all) event TokensInitialized(initialSupply: UFix64)
    access(all) event TokensMinted(amount: UFix64, to: Address?) // Modified
    access(all) event TokensTransferred(amount: UFix64, from: Address?, to: Address?)

    // Vault resource (unchanged)
    access(all) resource Vault: FungibleToken.Vault {
        access(all) var balance: UFix64

        init(balance: UFix64) {
            self.balance = balance
        }

        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            pre { amount <= self.balance: "Insufficient balance" }
            self.balance = self.balance - amount
            emit TokensTransferred(amount: amount, from: self.owner!.address, to: nil)
            return <- create Vault(balance: amount)
        }

        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @MyToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensTransferred(amount: vault.balance, from: vault.owner?.address, to: self.owner!.address)
            destroy vault
        }

        access(all) view fun getBalance(): UFix64 {
            return self.balance
        }

        access(all) fun createEmptyVault(): @{FungibleToken.Vault} {
            return <- create Vault(balance: 0.0)
        }

        access(all) view fun getSupportedVaultTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[self.getType()] = true
            return supportedTypes
        }

        access(all) view fun isSupportedVaultType(type: Type): Bool {
            return self.getSupportedVaultTypes()[type] ?? false
        }

        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return amount <= self.balance
        }

        access(all) view fun getViews(): [Type] {
            return []
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }
    }

    // Replace Admin with Minter
    access(all) resource Minter {
        access(all) fun mintTokens(amount: UFix64, to: Address?): @MyToken.Vault {
            MyToken.totalSupply = MyToken.totalSupply + amount
            let vault <- create Vault(balance: amount)
            emit TokensMinted(amount: amount, to: to)
            return <-vault
        }
    }

    access(all) fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault} {
        return <- create Vault(balance: 0.0)
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return []
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        return nil
    }

    init() {
        self.totalSupply = 0.0
        self.VaultStoragePath = /storage/MyTokenVault
        self.VaultPublicPath = /public/MyTokenVault
        self.ReceiverPublicPath = /public/MyTokenReceiver
        self.AdminStoragePath = /storage/MyTokenAdmin

        // Save Minter (changed from Admin)
        let minter <- create Minter()
        self.account.storage.save(<-minter, to: self.AdminStoragePath)

        let vault <- create Vault(balance: 0.0)
        self.account.storage.save(<-vault, to: self.VaultStoragePath)

        let vaultCap = self.account.capabilities.storage.issue<&MyToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(vaultCap, at: self.VaultPublicPath)
        let receiverCap = self.account.capabilities.storage.issue<&MyToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(receiverCap, at: self.ReceiverPublicPath)

        emit TokensInitialized(initialSupply: 0.0)
    }
}
