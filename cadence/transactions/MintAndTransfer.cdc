import MyToken from "MyToken"

transaction(amount: UFix64, recipient: Address) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Borrow Admin resource
        let admin = signer.storage.borrow<&MyToken.Admin>(from: /storage/MyTokenAdmin)
            ?? panic("Admin resource not found")
        log("Borrowed Admin resource")

        // Mint tokens to recipient
        admin.mintTokens(amount: amount, recipient: recipient)
        log("Minted ".concat(amount.toString()).concat(" tokens to ").concat(recipient.toString()))

        // Borrow signer's vault
        let signerVault = signer.storage.borrow<&MyToken.Vault>(from: /storage/MyTokenVault)
            ?? panic("Signer vault not found")
        log("Borrowed signer vault")

        // Borrow recipient's vault
        let recipientVault = getAccount(recipient)
            .capabilities.get<&MyToken.Vault>(/public/MyTokenVault)
            .borrow()
            ?? panic("Recipient vault not found")
        log("Borrowed recipient vault")

        // Transfer half the amount
        let tokens <- signerVault.withdraw(amount: amount / 2.0, from: signer.address)
        recipientVault.deposit(amount: tokens.balance)
        log("Transferred ".concat(tokens.balance.toString()).concat(" tokens to ").concat(recipient.toString()))

        // Destroy temporary vault
        destroy tokens
        log("Transaction completed")
    }
}