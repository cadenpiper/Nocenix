import FungibleToken from "FungibleToken"
import Nocenix from "Nocenix"

transaction(amount: UFix64) {
    let vault: &Nocenix.Vault

    prepare(signer: auth(Storage) &Account) {
        // Borrow the user's vault
        self.vault = signer.storage.borrow<&Nocenix.Vault>(from: Nocenix.VaultStoragePath)
            ?? panic("Vault not found")
    }

    execute {
        // Burn the specified amount of tokens
        self.vault.burn(amount: amount)
    }
}
