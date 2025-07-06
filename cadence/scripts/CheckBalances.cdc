import FungibleToken from "FungibleToken"
import Nocenix from "Nocenix"

access(all) fun main(recipient: Address): {String: UFix64} {
    // Get recipient's vault balance
    let recipientVaultCap = getAccount(recipient).capabilities.get<&{FungibleToken.Vault}>(Nocenix.ReceiverPublicPath)
    let recipientVault = recipientVaultCap.borrow()
        ?? panic("Recipient vault not found")
    let userBalance = recipientVault.balance

    // Get total supply
    let totalSupply = Nocenix.totalSupply

    return {
        "userBalance": userBalance,
        "totalSupply": totalSupply
    }
}