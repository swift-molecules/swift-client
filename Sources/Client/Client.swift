public struct Client<Input: ~Copyable, Output: ~Copyable, Failure: Swift.Error> {

    public let run: (consuming Input) async throws(Failure) -> Output

    public init(
        run: @escaping (consuming Input) async throws(Failure) -> Output
    ) {
        self.run = run
    }
}
