import FungibleToken from "FungibleToken"
import Nocenix from "Nocenix"

transaction(amount: UFix64, recipient: Address) {
    let admin: &Nocenix.Admin

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
    }

    execute {
        // Call mint to mint tokens to recipient
        self.admin.mint(amount: amount, to: recipient)
    }
}
