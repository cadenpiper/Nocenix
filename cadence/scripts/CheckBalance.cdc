import MyToken from "MyToken"

access(all) fun main(account: Address): UFix64 {
    let vault = getAccount(account)
        .capabilities.get<&MyToken.Vault>(/public/MyTokenVault)
        .borrow()
        ?? panic("Vault not found")
    return vault.getBalance()
}