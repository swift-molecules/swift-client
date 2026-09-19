extension Client where Input: ~Copyable, Output: ~Copyable {

    @inlinable
    public func callAsFunction(_ input: consuming Input) async throws(Failure) -> Output {
        try await run(input)
    }
}
