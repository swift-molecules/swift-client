public import Either

extension Client where Input: ~Copyable, Output: ~Copyable {

    public func collapsed<External: Swift.Error>() -> Client<Input, Output, External>
    where Failure == Either<External, Swift.Never> {
        .init(
            run: { input throws(External) in
                do throws(Either<External, Swift.Never>) {
                    return try await self(input)
                } catch {
                    throw error.value
                }
            }
        )
    }

    public func collapsed<Refusal: Swift.Error>() -> Client<Input, Output, Refusal>
    where Failure == Either<Swift.Never, Refusal> {
        .init(
            run: { input throws(Refusal) in
                do throws(Either<Swift.Never, Refusal>) {
                    return try await self(input)
                } catch {
                    throw error.value
                }
            }
        )
    }
}
