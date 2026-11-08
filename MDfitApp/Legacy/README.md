# Legacy native screens (not compiled)

The first native prototype: SwiftUI screens built against sample data and a placeholder API
(`api.mdfitsrq.com`, which doesn't exist). They aren't part of the app target any more — the app now
wraps the real member app at https://www.mymdfit.com/account (see `Sources/MDfit`). Kept here so
individual screens (workout player, pain map) can be rebuilt natively later against the real backend.
