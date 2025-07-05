import FungibleToken from "FungibleToken"
import MyToken from "MyToken"

transaction(amount: UFix64, recipient: Address) {
    let minter: &MyToken.Minter
    let recipientVault: &MyToken.Vault

    prepare(admin: auth(Storage) &Account, recipientAcct: auth(Storage, Capabilities) &Account) {
        self.minter = admin.storage.borrow<&MyToken.Minter>(from: MyToken.AdminStoragePath)
            ?? panic("Minter not found")

        if recipientAcct.storage.borrow<&MyToken.Vault>(from: MyToken.VaultStoragePath) == nil {
            let vault <- MyToken.createEmptyVault(vaultType: Type<@MyToken.Vault>())
            recipientAcct.storage.save(<-vault, to: MyToken.VaultStoragePath)
            let vaultCap = recipientAcct.capabilities.storage
                .issue<&MyToken.Vault>(MyToken.VaultStoragePath)
            recipientAcct.capabilities.publish(vaultCap, at: MyToken.VaultPublicPath)
            let receiverCap = recipientAcct.capabilities.storage
                .issue<&MyToken.Vault>(MyToken.VaultStoragePath)
            recipientAcct.capabilities.publish(receiverCap, at: MyToken.ReceiverPublicPath)
        }

        self.recipientVault = recipientAcct.capabilities
            .get<&MyToken.Vault>(MyToken.ReceiverPublicPath)
            .borrow()
            ?? panic("Recipient Vault not found")
    }

    execute {
        let newVault <- self.minter.mintTokens(amount: amount, to: recipient)
        self.recipientVault.deposit(from: <-newVault)
    }
}
