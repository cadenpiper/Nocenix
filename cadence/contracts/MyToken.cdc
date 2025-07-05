import FungibleToken from "FungibleToken"

access(all) contract MyToken: FungibleToken {
    access(all) var totalSupply: UFix64
    access(all) let maxSupply: UFix64
    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultPublicPath: PublicPath
    access(all) let ReceiverPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath

    access(all) event TokensInitialized(initialSupply: UFix64)
    access(all) event TokensMinted(amount: UFix64, to: Address?)
    access(all) event TokensBurned(amount: UFix64, from: Address?)
    access(all) event TokensTransferred(amount: UFix64, from: Address?, to: Address?)

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

        access(all) fun burn(amount: UFix64) {
            pre { amount <= self.balance: "Insufficient balance" }
            self.balance = self.balance - amount
            MyToken.totalSupply = MyToken.totalSupply - amount
            emit TokensBurned(amount: amount, from: self.owner?.address)
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

    access(all) resource Admin {
        access(all) fun mintAndBurn(amount: UFix64, to: Address) {
            // Borrow contract vault to retrieve values: balance, current supply, and max supply
            let contractVault = MyToken.account.storage.borrow<&MyToken.Vault>(from: MyToken.VaultStoragePath)
                ?? panic("Contract vault not found")
            let contractBalance = contractVault.balance
            let currentSupply = MyToken.totalSupply
            let maxSupply = MyToken.maxSupply

            assert(amount <= contractBalance, message: "Insufficient contract balance")
            assert(currentSupply <= maxSupply, message: "Exceeds max supply")

            // Burn tokens before minting
            contractVault.burn(amount: amount)

            // Recalibrate total supply
            MyToken.totalSupply = MyToken.totalSupply + amount
            
            // Mint amount to user account
            let userVaultCap: Capability<&{FungibleToken.Vault}> = getAccount(to).capabilities.get<&{FungibleToken.Vault}>(MyToken.ReceiverPublicPath)
            let userVault: &{FungibleToken.Vault} = userVaultCap.borrow() ?? panic("User vault not found")
            let newVault <- create Vault(balance: amount)
            userVault.deposit(from: <-newVault)
            emit TokensMinted(amount: amount, to: to)
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
        self.totalSupply = 1000000000.0
        self.maxSupply = 1000000000.0
        self.VaultStoragePath = /storage/MyTokenVault
        self.VaultPublicPath = /public/MyTokenVault
        self.ReceiverPublicPath = /public/MyTokenReceiver
        self.AdminStoragePath = /storage/MyTokenAdmin

        let vault <- create Vault(balance: self.totalSupply)
        self.account.storage.save(<-vault, to: self.VaultStoragePath)

        let vaultCap = self.account.capabilities.storage.issue<&MyToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(vaultCap, at: self.VaultPublicPath)
        let receiverCap = self.account.capabilities.storage.issue<&MyToken.Vault>(self.VaultStoragePath)
        self.account.capabilities.publish(receiverCap, at: self.ReceiverPublicPath)

        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)

        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
