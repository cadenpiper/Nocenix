import MetadataViews from "MetadataViews"
import FungibleTokenMetadataViews from "FungibleTokenMetadataViews"
import MyToken from "MyToken"

access(all) fun main(contractAddress: Address): AnyStruct {
    // Directly resolve the FTDisplay view from the contract
    let displayView = MyToken.resolveContractView(
        resourceType: nil,
        viewType: Type<FungibleTokenMetadataViews.FTDisplay>()
    ) ?? panic("FTDisplay view not found")
    
    return displayView
}
