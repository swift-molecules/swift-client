import Client_Macro
import Interface_Macro
import Testing

@Interface
struct Greeting: Greeting.`Protocol` {
    struct Name: Hashable {
        var value: String
    }

    struct Message: Equatable {
        var value: String
    }

    @Operations
    @Client
    protocol `Protocol` {
        func greet(_ name: Name) async -> Message
    }
}

@Interface
struct Counter: Counter.`Protocol` {
    struct Limit: Hashable {
        var value: Int
    }

    struct Value: Equatable {
        var value: Int
    }

    enum Error: Swift.Error, Equatable {
        case exceeded
    }

    @Operations
    @Client
    protocol `Protocol` {
        func increment(limit: Limit) async throws(Error) -> Value
        func reset() async
    }
}

@Interface
struct Example: Example.`Protocol` {
    @Operations
    @Client
    protocol `Protocol` {
        associatedtype Greeting: Client_Macro_Tests::Greeting.`Protocol`
        associatedtype Counter: Client_Macro_Tests::Counter.`Protocol`

        var greeting: Greeting { get }
        var counter: Counter { get }
    }
}

private enum Transport: Swift.Error, Equatable {
    case unreachable
    case malformed
}

@Suite
private struct `Consumer Tests` {
    @Test
    func `a leaf client lifts every operation failure into the external coproduct`() async throws {
        let client = Greeting.Client<Transport>(
            greet: { request throws(Either<Transport, Never>) in
                .init(value: "Hello, \(request.name.value)!")
            }
        )

        #expect(try await client.greet(.init(.init(value: "Blob"))) == .init(value: "Hello, Blob!"))
    }

    @Test
    func `a leaf client preserves labels and the domain refusal branch`() async {
        let client = Counter.Client<Transport>(
            increment: { request throws(Either<Transport, Counter.Error>) in
                guard request.limit.value < 10 else { throw .right(.exceeded) }
                return .init(value: request.limit.value + 1)
            },
            reset: { _ throws(Either<Transport, Never>) in }
        )

        await #expect(throws: Either<Transport, Counter.Error>.right(.exceeded)) {
            try await client.increment(.init(limit: .init(value: 10)))
        }
    }

    @Test
    func `a root client composes child clients over one external failure`() async throws {
        let client = Example.Client<Transport>(
            greeting: .init(greet: { request throws(Either<Transport, Never>) in .init(value: "Hi \(request.name.value)") }),
            counter: .init(
                increment: { _ throws(Either<Transport, Counter.Error>) in throw .left(.unreachable) },
                reset: { _ throws(Either<Transport, Never>) in }
            )
        )

        #expect(try await client.greeting.greet(.init(.init(value: "Blob"))) == .init(value: "Hi Blob"))
        await #expect(throws: Either<Transport, Counter.Error>.left(.unreachable)) {
            try await client.counter.increment(.init(limit: .init(value: 1)))
        }
    }
}
