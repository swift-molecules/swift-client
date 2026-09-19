import Operation_Syntax
import Product_Syntax
public import Interface_Syntax
public import SwiftSyntax
import SwiftSyntaxBuilder

extension Client {
    public enum Derivation {
        public static func peers(of signature: Interface.Analysis) -> [DeclSyntax] {
            let access = signature.product.access.map { "\($0.name.text) " } ?? ""
            let owner = signature.owner.trimmedDescription
            let operations = signature.symbols.map { symbol in
                "func \(symbol.caseName)(_ input: \(symbol.inputParameter(owner: owner))) async throws(Either<External, \(symbol.failure.trimmedDescription)>) -> \(symbol.output.trimmedDescription)"
            }
            let children = signature.children.map { child in
                "var \(child.name.text): \(child.domain.trimmedDescription).Client<External> { get }"
            }
            let adapters = signature.symbols.map { symbol in
                """
                let \(symbol.caseName): Client::Client<\(owner).\(symbol.name).Input, \(owner).\(symbol.name).Output, Either<External, \(owner).\(symbol.name).Failure>> =
                    Client::Client<\(owner).\(symbol.name).Input, \(owner).\(symbol.name).Output, \(owner).\(symbol.name).Failure>(
                        run: { (input: consuming \(owner).\(symbol.name).Input) async throws(\(owner).\(symbol.name).Failure) in
                            return \(symbol.prefix)\(owner).\(symbol.name).run(owner, input)
                        }
                    ).promoted()
                """
            } + signature.children.map { child in
                "let \(child.name.text): \(child.domain.trimmedDescription).Client<External> = \(child.domain.trimmedDescription).ClientDefinition.live(owner.\(child.name.text))"
            }
            let adapterArguments = signature.symbols.map { "\($0.caseName): \($0.caseName).run" }
                + signature.children.map { "\($0.name.text): \($0.name.text)" }
            return [DeclSyntax(stringLiteral: """
                \(access)enum ClientDefinition {
                    /// Lift a modeled owner through the canonical runtime Client promotion.
                    \(access)static func live<External: Swift.Error>(_ owner: \(owner)) -> \(owner).Client<External> {
                        \(adapters.joined(separator: "\n"))
                        return \(owner).Client<External>(\(adapterArguments.joined(separator: ", ")))
                    }
                    @Product
                    \(access)protocol Model {
                        associatedtype External: Swift.Error
                        \((operations + children).joined(separator: "\n"))
                    }
                }
                """), DeclSyntax(stringLiteral: """
                \(access)typealias Client<External: Swift.Error> = ClientDefinition.Product<External>
                """)]
        }
    }
}
