import Client_Consumer_Fixtures
import Client_Macro
import Testing

private enum TransportFailure: Error { case unavailable }
@Test func publicGeneratedClientCrossesAModuleBoundary() async throws {
    let client = PublicGreeting.Client<TransportFailure>(greet: { input throws(Either<TransportFailure, Never>) in
        "Hello, " + input.name
    })
    #expect(try await client.greet(.init("World")) == "Hello, World")
    let owner = PublicGreeting(greet: { "Hello, " + $0.name })
    try await owner(.greet("World"))
}

@Test func generatedClientLiftsTheOwnerAndIndexedApplicationKeepsItsResult() async throws {
    let owner = PublicGreeting(greet: { "Hello, " + $0.name })
    let client: PublicGreeting.Client<TransportFailure> = PublicGreeting.ClientDefinition.live(owner)
    #expect(try await client.greet(.init("World")) == "Hello, World")
    let application = PublicGreeting.Greet.Application(.init("Typed"))
    let result: String = try await application.run(on: owner)
    #expect(result == "Hello, Typed")
}
