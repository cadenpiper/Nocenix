import FungibleToken from "FungibleToken"
import MyToken from "MyToken"

transaction(amount: UFix64, recipient: Address) {
    let admin: &MyToken.Admin
    let recipientVault: &{FungibleToken.Vault}

    prepare(adminAcct: auth(Storage, Capabilities) &Account, recipientAcct: auth(Storage, Capabilities) &Account) {
        // Borrow Admin resource
        self.admin = adminAcct.storage.borrow<&MyToken.Admin>(from: MyToken.AdminStoragePath)
            ?? panic("Admin not found")

        // Check if recipient has a vault, create if not
        if recipientAcct.storage.borrow<&MyToken.Vault>(from: MyToken.VaultStoragePath) == nil {
            let vault <- MyToken.createEmptyVault(vaultType: Type<@MyToken.Vault>())
            recipientAcct.storage.save(<-vault, to: MyToken.VaultStoragePath)

            let vaultCap = recipientAcct.capabilities.storage
                .issue<&{FungibleToken.Vault}>(MyToken.VaultStoragePath)
            recipientAcct.capabilities.publish(vaultCap, at: MyToken.VaultPublicPath)

            let receiverCap = recipientAcct.capabilities.storage
                .issue<&{FungibleToken.Vault}>(MyToken.VaultStoragePath)
            recipientAcct.capabilities.publish(receiverCap, at: MyToken.ReceiverPublicPath)
        }

        // Borrow recipient vault
        let vaultCap = recipientAcct.capabilities.get<&{FungibleToken.Vault}>(MyToken.ReceiverPublicPath)
        self.recipientVault = vaultCap.borrow() ?? panic("Recipient vault not found")
    }

    execute {
        // Call mintAndBurn to burn from contract vault and mint to recipient
        self.admin.mintAndBurn(amount: amount, to: recipient)
    }
}
