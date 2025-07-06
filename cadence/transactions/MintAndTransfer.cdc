import FungibleToken from "FungibleToken"
import Nocenix from "Nocenix"

transaction(amount: UFix64, recipient: Address) {
    let admin: &Nocenix.Admin
    let recipientVault: &{FungibleToken.Vault}

    prepare(adminAcct: auth(Storage, Capabilities) &Account, recipientAcct: auth(Storage, Capabilities) &Account) {
        // Borrow Admin resource
        self.admin = adminAcct.storage.borrow<&Nocenix.Admin>(from: Nocenix.AdminStoragePath)
            ?? panic("Admin not found")

        // Check if recipient has a vault, create if not
        if recipientAcct.storage.borrow<&Nocenix.Vault>(from: Nocenix.VaultStoragePath) == nil {
            let vault <- Nocenix.createEmptyVault(vaultType: Type<@Nocenix.Vault>())
            recipientAcct.storage.save(<-vault, to: Nocenix.VaultStoragePath)

            let vaultCap = recipientAcct.capabilities.storage
                .issue<&{FungibleToken.Vault}>(Nocenix.VaultStoragePath)
            recipientAcct.capabilities.publish(vaultCap, at: Nocenix.VaultPublicPath)

            let receiverCap = recipientAcct.capabilities.storage
                .issue<&{FungibleToken.Vault}>(Nocenix.VaultStoragePath)
            recipientAcct.capabilities.publish(receiverCap, at: Nocenix.ReceiverPublicPath)
        }

        // Borrow recipient vault
        let vaultCap = recipientAcct.capabilities.get<&{FungibleToken.Vault}>(Nocenix.ReceiverPublicPath)
        self.recipientVault = vaultCap.borrow() ?? panic("Recipient vault not found")
    }

    execute {
        // Call mintAndBurn to burn from contract vault and mint to recipient
        self.admin.mintAndBurn(amount: amount, to: recipient)
    }
}
