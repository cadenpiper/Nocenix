import FungibleToken from "FungibleToken"
import Nocenix from "Nocenix"

access(all) fun main(recipient: Address, contractAddress: Address): {String: UFix64} {
    // Get recipient's vault balance
    let recipientVaultCap = getAccount(recipient).capabilities.get<&{FungibleToken.Vault}>(Nocenix.ReceiverPublicPath)
    let recipientVault = recipientVaultCap.borrow()
        ?? panic("Recipient vault not found")
    let userBalance = recipientVault.balance

    // Get contract vault balance via public capability
    let contractVaultCap = getAccount(contractAddress).capabilities.get<&{FungibleToken.Vault}>(Nocenix.VaultPublicPath)
    let contractVault = contractVaultCap.borrow()
        ?? panic("Contract vault not found")
    let contractBalance = contractVault.balance

    // Get total supply
    let totalSupply = Nocenix.totalSupply

    return {
        "userBalance": userBalance,
        "contractBalance": contractBalance,
        "totalSupply": totalSupply
    }
}
