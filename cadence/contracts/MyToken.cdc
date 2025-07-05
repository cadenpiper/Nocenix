import FungibleToken from "FungibleToken"

access(all) contract MyToken: FungibleToken {
    // Total supply of tokens
    access(all) var totalSupply: UFix64

    // Storage and public paths
    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultPublicPath: PublicPath
    access(all) let ReceiverPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath

    // Events
    access(all) event TokensInitialized(initialSupply: UFix64)
    access(all) event TokensMinted(amount: UFix64, to: Address)
    access(all) event TokensTransferred(amount: UFix64, from: Address?, to: Address?)

    // Vault resource
    access(all) resource Vault: FungibleToken.Vault {
        access(all) var balance: UFix64

        init(balance: UFix64) {
            self.balance = balance
        }

        // Withdraw tokens
        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            pre { amount <= self.balance: "Insufficient balance" }
            self.balance = self.balance - amount
            emit TokensTransferred(amount: amount, from: self.owner!.address, to: nil)
            return <- create Vault(balance: amount)
        }

        // Deposit tokens
        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let vault <- from as! @MyToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensTransferred(amount: vault.balance, from: vault.owner?.address, to: self.owner!.address)
            destroy vault
        }

        // Get balance
        access(all) view fun getBalance(): UFix64 {
            return self.balance
        }

        // Create empty vault
        access(all) fun createEmptyVault(): @{FungibleToken.Vault} {
            return <- create Vault(balance: 0.0)
        }

        // Query supported vault types
        access(all) view fun getSupportedVaultTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[self.getType()] = true
            return supportedTypes
        }

        access(all) view fun isSupportedVaultType(type: Type): Bool {
            return self.getSupportedVaultTypes()[type] ?? false
        }

        // Check withdrawable amount
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return amount <= self.balance
        }

        // Metadata views
        access(all) view fun getViews(): [Type] {
            return []
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }
    }

    // Admin resource
    access(all) resource Admin {
        access(all) fun mintTokens(amount: UFix64, recipient: Address) {
            let recipientVault = getAccount(recipient)
                .capabilities.get<&MyToken.Vault>(MyToken.ReceiverPublicPath)
                .borrow()
                ?? panic("Recipient vault not found")
            let vault <- create Vault(balance: amount)
            MyToken.totalSupply = MyToken.totalSupply + amount
            recipientVault.deposit(from: <-vault)
            emit TokensMinted(amount: amount, to: recipient)
        }
    }

    // Create empty vault
    access(all) fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault} {
        return <- create Vault(balance: 0.0)
    }

    // Metadata views
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return []
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        return nil
    }

    // Contract initializer
    init() {
        self.totalSupply = 0.0
        self.VaultStoragePath = /storage/MyTokenVault
        self.VaultPublicPath = /public/MyTokenVault
        self.ReceiverPublicPath = /public/MyTokenReceiver
        self.AdminStoragePath = /storage/MyTokenAdmin

        // Save admin
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)

        // Save empty vault
        let vault <- create Vault(balance: 0.0)
        self.account.storage.save(<-vault, to: self.VaultStoragePath)

        // Publish capabilities
        let vaultCap = self.account.capabilities.storage.issue<&MyToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(vaultCap, at: self.VaultPublicPath)
        let receiverCap = self.account.capabilities.storage.issue<&MyToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(receiverCap, at: self.ReceiverPublicPath)

        emit TokensInitialized(initialSupply: 0.0)
    }
}