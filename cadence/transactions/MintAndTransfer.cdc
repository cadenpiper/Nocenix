import FungibleToken from "FungibleToken"
import MyToken from "MyToken"

transaction(amount: UFix64, recipient: Address) {
    let admin: &MyToken.Admin
    let recipientVault: &{FungibleToken.Vault}
    let senderVault: auth(FungibleToken.Withdraw) &MyToken.Vault
    let signerAddress: Address
    let initialSenderBalance: UFix64
    let initialRecipientBalance: UFix64

    prepare(signer: auth(Storage, Capabilities, FungibleToken.Withdraw) &Account, recipientAcct: auth(Storage, Capabilities) &Account) {
        self.signerAddress = signer.address
        self.admin = signer.storage.borrow<&MyToken.Admin>(from: MyToken.AdminStoragePath)
            ?? panic("Admin not found")

        if recipientAcct.storage.borrow<&MyToken.Vault>(from: MyToken.VaultStoragePath) == nil {
            let vault <- MyToken.createEmptyVault(vaultType: Type<@MyToken.Vault>())
            recipientAcct.storage.save(<-vault, to: MyToken.VaultStoragePath)
            let vaultCap = recipientAcct.capabilities.storage.issue<&MyToken.Vault>(MyToken.VaultStoragePath)
            recipientAcct.capabilities.publish(vaultCap, at: MyToken.VaultPublicPath)
            let receiverCap = recipientAcct.capabilities.storage.issue<&MyToken.Vault>(MyToken.VaultStoragePath)
            recipientAcct.capabilities.publish(receiverCap, at: MyToken.ReceiverPublicPath)
        }
        self.recipientVault = recipientAcct.capabilities.get<&{FungibleToken.Vault}>(MyToken.ReceiverPublicPath).borrow()
            ?? panic("Recipient vault not found")
        self.initialRecipientBalance = self.recipientVault.balance

        if signer.storage.borrow<&MyToken.Vault>(from: MyToken.VaultStoragePath) == nil {
            let vault <- MyToken.createEmptyVault(vaultType: Type<@MyToken.Vault>())
            signer.storage.save(<-vault, to: MyToken.VaultStoragePath)
            let vaultCap = signer.capabilities.storage.issue<&MyToken.Vault>(MyToken.VaultStoragePath)
            signer.capabilities.publish(vaultCap, at: MyToken.VaultPublicPath)
            let receiverCap = signer.capabilities.storage.issue<&MyToken.Vault>(MyToken.VaultStoragePath)
            signer.capabilities.publish(receiverCap, at: MyToken.ReceiverPublicPath)
        }
        self.senderVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &MyToken.Vault>(from: MyToken.VaultStoragePath)
            ?? panic("Sender vault not found")
        self.initialSenderBalance = self.senderVault.balance
    }

    execute {
        self.admin.mintTokens(amount: amount, recipient: self.signerAddress)
        let tokens <- self.senderVault.withdraw(amount: amount / 2.0)
        self.recipientVault.deposit(from: <-tokens)
    }

    post {
        self.senderVault.balance == self.initialSenderBalance + amount / 2.0: "Sender balance incorrect"
        self.recipientVault.balance == self.initialRecipientBalance + amount / 2.0: "Recipient balance incorrect"
    }
}