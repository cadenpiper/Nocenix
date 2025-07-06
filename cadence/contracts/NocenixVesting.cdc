import FungibleToken from "FungibleToken"
import Nocenix from "Nocenix"

access(all) contract NocenixVesting {
    // Storage and public paths
    access(all) let VestingStoragePath: StoragePath
    access(all) let VestingPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath

    // Events
    access(all) event VestingScheduleCreated(recipient: Address, totalAmount: UFix64)
    access(all) event TokensClaimed(recipient: Address, amount: UFix64)

    // Admin resource placeholder
    access(all) resource Admin {
        init() {}
    }

    init() {
        self.VestingStoragePath = /storage/NocenixVestingSchedule
        self.VestingPublicPath = /public/NocenixVestingSchedule
        self.AdminStoragePath = /storage/NocenixVestingAdmin

        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)
    }
}
