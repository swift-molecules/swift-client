public import Interface_Macro_Core
public import Operation_Macro_Core
public import Product_Macro_Core
public import SwiftSyntax
import SwiftSyntaxBuilder

// A client is the interface's arrows lifted over an external failure: every operation takes the same Input the
// interface is called with (its symbol's `Input`) and fails with `Either<External, Failure>`. The names come
// from the operations' analysis; nothing is re-derived here.
extension Client {
    public enum Derivation {
        public static func peers(of signature: Interface.Analysis) -> [DeclSyntax] {
            let access = signature.product.access.map { "\($0.name.text) " } ?? ""
            return [client(of: signature, access: access)]
        }

        private static func client(of signature: Interface.Analysis, access: String) -> DeclSyntax {
            let owner = signature.owner.trimmedDescription
            let symbols = signature.symbols
            let storedArrows = symbols.map { symbol in
                "    private let _\(symbol.caseName): \(arrow(of: symbol, owner: owner))"
            }
            let storedChildren = signature.children.map { child in
                "    \(access)let \(child.name.text): \(child.domain.trimmedDescription).Client<External>"
            }
            let parameters = symbols.map { symbol in
                "\(symbol.caseName): \(arrow(of: symbol, owner: owner))"
            } + signature.children.map { child in
                "\(child.name.text): \(child.domain.trimmedDescription).Client<External>"
            }
            let assignments = symbols.map { symbol in
                "        self._\(symbol.caseName) = \(symbol.caseName)"
            } + signature.children.map { child in
                "        self.\(child.name.text) = \(child.name.text)"
            }
            let forwarding = symbols.map { symbol in
                """
                    \(access)func \(symbol.signature.name.text)\(symbol.signature.declaration.signature.parameterClause.trimmedDescription) async throws(\(failure(of: symbol))) -> \(symbol.output.trimmedDescription) {
                        try await self._\(symbol.caseName)(\(symbol.inputPath(owner: owner))(\(symbol.construction)))
                    }
                """
            }
            let initializer = """
                    \(access)init(\(parameters.joined(separator: ", "))) {
                \(assignments.joined(separator: "\n"))
                    }
                """
            let members = (storedArrows + storedChildren + [initializer] + forwarding)
                .joined(separator: "\n\n")
            return DeclSyntax(stringLiteral: """
                \(access)struct Client<External: Swift.Error> {
                \(members)
                }
                """)
        }

        private static func failure(of symbol: Interface.Analysis.Symbol) -> String {
            "Either<External, \(symbol.failure.trimmedDescription)>"
        }

        private static func arrow(of symbol: Interface.Analysis.Symbol, owner: String) -> String {
            "Client::Client<\(symbol.inputPath(owner: owner)), \(symbol.output.trimmedDescription), \(failure(of: symbol))>"
        }
    }
}
