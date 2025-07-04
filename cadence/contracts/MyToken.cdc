import FungibleToken from "FungibleToken"
import FungibleTokenMetadataViews from "FungibleTokenMetadataViews"
import MetadataViews from "MetadataViews"

access(all) contract MyToken: FungibleToken {
    // Total supply of tokens
    access(all) var totalSupply: UFix64

    // Storage and public paths
    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultPublicPath: PublicPath
    access(all) let ReceiverPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath

    // Events
    access(all) event TokensInitialized(InitialSupply: UFix64)
    access(all) event TokensMinted(amount: UFix64, to: Address)
    access(all) event TokensTransferred(amount: UFix64, from: Address, to: Address?)

    // Vault resource to store tokens
    access(all) resource Vault {
        // Token balance field
        access(all) var balance: UFix64

        // Initialize vault
        init(balance: UFix64) {
            self.balance = balance
        }

        // Deposit tokens
        access(all) fun deposit(amount: UFix64) {
            self.balance = self.balance + amount
        }

        // Withdraw tokens
        access(all) fun withdraw(amount: UFix64, from: Address): @Vault {
            pre { amount <= self.balance: "Insufficient balance" }
            self.balance = self.balance - amount
            emit TokensTransferred(amount: amount, from: from, to: nil)
            return <- create Vault(balance: amount)
        }

        // Get balance
        access(all) fun getBalance(): UFix64 {
            return self.balance
        }
    }

    // Admin resource to mint tokens
    access(all) resource Admin {
        // Mint tokens to a recipient address
        access(all) fun mintTokens(amount: UFix64, recipient: Address) {
            let recipientVault = getAccount(recipient)
                .capabilities.get<&MyToken.Vault>(/public/MyTokenVault)
                .borrow()
                ?? panic("Recipient vault not found")
            MyToken.totalSupply = MyToken.totalSupply + amount
            recipientVault.deposit(amount: amount)
            emit TokensMinted(amount: amount, to: recipient)
        }
    }

    // Create a new empty vault
    access(all) fun createVault(): @Vault {
        return <- create Vault(balance: 0.0)
    }

    // Contract initializer
    init() {
        self.totalSupply = 0.0
        self.VaultStoragePath = /storage/MyTokenVault
        self.VaultPublicPath = /public/MyTokenVault
        self.ReceiverPublicPath = /public/MyTokenReceiver
        self.AdminStoragePath = /storage/MyTokenAdmin

        // Save Admin resource
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)

        // Save empty Vault
        let vault <- create Vault(balance: 0.0)
        self.account.storage.save(<-vault, to: self.VaultStoragePath)

        // Publish capabilities
        let vaultCap = self.account.capabilities.storage.issue<&MyToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(vaultCap, at: self.VaultPublicPath)

        let receiverCap = self.account.capabilities.storage.issue<&MyToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(receiverCap, at: self.VaultPublicPath)

        // Emit TokensInitialized event
        emit TokensInitialized(InitialSupply: 0.0)
    }
}