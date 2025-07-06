import FungibleToken from "FungibleToken"
import MetadataViews from "MetadataViews"
import FungibleTokenMetadataViews from "FungibleTokenMetadataViews"

access(all) contract MyToken: FungibleToken {
    access(all) var totalSupply: UFix64
    access(all) let maxSupply: UFix64
    access(all) let VaultStoragePath: StoragePath
    access(all) let VaultPublicPath: PublicPath
    access(all) let ReceiverPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath

    // Events
    access(all) event TokensInitialized(initialSupply: UFix64)
    access(all) event TokensMinted(amount: UFix64, to: Address?)
    access(all) event TokensBurned(amount: UFix64, from: Address?)
    access(all) event TokensTransferred(amount: UFix64, from: Address?, to: Address?)

    // Metadata views
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<FungibleTokenMetadataViews.FTView>(),
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>(),
            Type<FungibleTokenMetadataViews.TotalSupply>()
        ]
    }

    // Resolve metadata views
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<FungibleTokenMetadataViews.FTView>():
                return FungibleTokenMetadataViews.FTView(
                    ftDisplay: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?,
                    ftVaultData: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
                )
            case Type<FungibleTokenMetadataViews.FTDisplay>():
                return FungibleTokenMetadataViews.FTDisplay(
                    name: "MyToken",
                    symbol: "MTK",
                    description: "A fungible token for the MyToken project on Flow.",
                    externalURL: MetadataViews.ExternalURL(""), // Placeholder, add later
                    logos: MetadataViews.Medias([]), // Empty logos
                    socials: {} // Empty socials
                )
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                return FungibleTokenMetadataViews.FTVaultData(
                    storagePath: self.VaultStoragePath,
                    receiverPath: self.ReceiverPublicPath,
                    metadataPath: self.VaultPublicPath,
                    receiverLinkedType: Type<&MyToken.Vault>(),
                    metadataLinkedType: Type<&MyToken.Vault>(),
                    createEmptyVaultFunction: (fun(): @{FungibleToken.Vault} {
                        return <-MyToken.createEmptyVault(vaultType: Type<@MyToken.Vault>())
                    })
                )
            case Type<FungibleTokenMetadataViews.TotalSupply>():
                return FungibleTokenMetadataViews.TotalSupply(
                    totalSupply: MyToken.totalSupply
                )
        }
        return nil
    }

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
            return MyToken.getContractViews(resourceType: nil)
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return MyToken.resolveContractView(resourceType: nil, viewType: view)
        }
    }

    access(all) resource Admin {
        access(all) fun mintAndBurn(amount: UFix64, to: Address) {
            let contractVault = MyToken.account.storage.borrow<&MyToken.Vault>(from: MyToken.VaultStoragePath)
                ?? panic("Contract vault not found")
            let contractBalance = contractVault.balance
            let currentSupply = MyToken.totalSupply
            let maxSupply = MyToken.maxSupply

            assert(amount <= contractBalance, message: "Insufficient contract balance")
            assert(currentSupply <= maxSupply, message: "Exceeds max supply")

            contractVault.burn(amount: amount)

            MyToken.totalSupply = MyToken.totalSupply + amount
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
