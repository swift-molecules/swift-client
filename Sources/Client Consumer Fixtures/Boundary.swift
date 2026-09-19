public import Client_Macro
public import Interface_Macro

@Interface
public struct PublicGreeting: PublicGreeting.Interface {
    @Client
    public protocol Interface {
        func greet(_ name: String) -> String
    }
}
