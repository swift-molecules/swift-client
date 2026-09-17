@_exported import Client
@_exported import Either
@_exported import Operation

@attached(peer, names: named(Client))
public macro Client() = #externalMacro(
    module: "Client_Macro_Plugin",
    type: "Macro"
)
