access(all) contract MyToken {
    // Total supply of tokens
    access(all) var totalSupply: UFix64

    // Event for minted tokens
    access(all) event TokensMinted(amount: UFix64, to: Address)

    // Event for transferred tokens, 'to' is optional
    access(all) event TokensTransferred(amount: UFix64, from: Address, to: Address?)

    // Vault resource to store tokens
    access(all) resource Vault {
        // Token balance field
        access(all) var balance: UFix64

        // Initialize vault
        init(balance: UFix64) {
            self.balance = balance
        }

        // Deposit tokens (public)
        access(all) fun deposit(amount: UFix64) {
            self.balance = self.balance + amount
        }

        // Withdraw tokens (public for simplicity)
        access(all) fun withdraw(amount: UFix64, from: Address): @Vault {
            pre { amount <= self.balance: "Insufficient balance" }
            self.balance = self.balance - amount
            emit TokensTransferred(amount: amount, from: from, to: nil)
            return <- create Vault(balance: amount)
        }

        // Get balance (public)
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

    // Contract initializer
    init() {
        self.totalSupply = 0.0

        // Save Admin resource
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: /storage/MyTokenAdmin)

        // Save empty Vault
        let vault <- create Vault(balance: 0.0)
        self.account.storage.save(<-vault, to: /storage/MyTokenVault)

        // Publish public capability
        self.account.capabilities.publish(
            self.account.capabilities.storage.issue<&MyToken.Vault>(/storage/MyTokenVault),
            at: /public/MyTokenVault
        )
    }

    // Create a new empty vault
    access(all) fun createVault(): @Vault {
        return <- create Vault(balance: 0.0)
    }
}