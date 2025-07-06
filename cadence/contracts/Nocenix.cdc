import FungibleToken from "FungibleToken"
import MetadataViews from "MetadataViews"
import FungibleTokenMetadataViews from "FungibleTokenMetadataViews"

access(all) contract Nocenix: FungibleToken {
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

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<FungibleTokenMetadataViews.FTView>(),
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>(),
            Type<FungibleTokenMetadataViews.TotalSupply>()
        ]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<FungibleTokenMetadataViews.FTView>():
                return FungibleTokenMetadataViews.FTView(
                    ftDisplay: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?,
                    ftVaultData: self.resolveContractView(resourceType: nil, viewType: Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
                )
            case Type<FungibleTokenMetadataViews.FTDisplay>():
                let media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://bafybeifv2n2peft2pwcowwyx2y3lzicpk2eni5bgtrictyw5bmblyrkx6u.ipfs.w3s.link/nocenapink.ico"
                    ),
                    mediaType: "image/vnd.microsoft.icon"
                )
                let medias = MetadataViews.Medias([media])
                return FungibleTokenMetadataViews.FTDisplay(
                    name: "Nocenix",
                    symbol: "NCX",
                    description: "Respective token for Nocena",
                    externalURL: MetadataViews.ExternalURL("https://www.nocena.com/"),
                    logos: medias,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/nocena_app")
                    }
                )
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                return FungibleTokenMetadataViews.FTVaultData(
                    storagePath: self.VaultStoragePath,
                    receiverPath: self.ReceiverPublicPath,
                    metadataPath: self.VaultPublicPath,
                    receiverLinkedType: Type<&Nocenix.Vault>(),
                    metadataLinkedType: Type<&Nocenix.Vault>(),
                    createEmptyVaultFunction: (fun(): @{FungibleToken.Vault} {
                        return <-Nocenix.createEmptyVault(vaultType: Type<@Nocenix.Vault>())
                    })
                )
            case Type<FungibleTokenMetadataViews.TotalSupply>():
                return FungibleTokenMetadataViews.TotalSupply(
                    totalSupply: Nocenix.totalSupply
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
            let vault <- from as! @Nocenix.Vault
            self.balance = self.balance + vault.balance
            emit TokensTransferred(amount: vault.balance, from: vault.owner?.address, to: self.owner!.address)
            destroy vault
        }

        access(all) fun burn(amount: UFix64) {
            pre { amount <= self.balance: "Insufficient balance" }
            self.balance = self.balance - amount
            Nocenix.totalSupply = Nocenix.totalSupply - amount
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
            return Nocenix.getContractViews(resourceType: nil)
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return Nocenix.resolveContractView(resourceType: nil, viewType: view)
        }
    }

    access(all) resource Admin {
        access(all) fun mint(amount: UFix64, to: Address) {
            pre {
                Nocenix.totalSupply + amount <= Nocenix.maxSupply: "Exceeds max supply"
            }
            Nocenix.totalSupply = Nocenix.totalSupply + amount
            let userVaultCap: Capability<&{FungibleToken.Vault}> = getAccount(to).capabilities.get<&{FungibleToken.Vault}>(Nocenix.ReceiverPublicPath)
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
        self.totalSupply = 0.0
        self.maxSupply = 1000000000.0
        self.VaultStoragePath = /storage/NocenixVault
        self.VaultPublicPath = /public/NocenixVault
        self.ReceiverPublicPath = /public/NocenixReceiver
        self.AdminStoragePath = /storage/NocenixAdmin

        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)

        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
