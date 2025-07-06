import MetadataViews from "MetadataViews"
import FungibleTokenMetadataViews from "FungibleTokenMetadataViews"
import Nocenix from "Nocenix"

access(all) fun main(contractAddress: Address): {String: AnyStruct} {
    // Directly resolve the FTDisplay view from the contract
    let displayView = Nocenix.resolveContractView(
        resourceType: nil,
        viewType: Type<FungibleTokenMetadataViews.FTDisplay>()
    ) ?? panic("FTDisplay view not found")

    // Cast to FTDisplay
    let display = displayView as! FungibleTokenMetadataViews.FTDisplay

    // Format output with explicit fields
    return {
        "name": display.name,
        "symbol": display.symbol,
        "description": display.description,
        "externalURL": display.externalURL.url,
        "logos": display.logos.items,
        "socials": display.socials
    }
}
