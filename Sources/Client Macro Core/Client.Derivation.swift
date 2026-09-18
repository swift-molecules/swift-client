public import SwiftSyntax
public import Interface_Macro_Core
import Product_Macro_Core
import SwiftSyntaxBuilder

// A client is the interface's arrows lifted over an external failure: every operation takes the same
// `Request` the interface is called with (its symbol's `Input`) and fails with `Either<External, Failure>`.
// The names come from the interface's naming table; nothing is re-derived here.
extension Client {
    public enum Derivation {
        public static func peers(of signature: Interface.Analysis) -> [DeclSyntax] {
            let access = signature.product.access.map { "\($0.name.text) " } ?? ""
            return [client(of: signature, access: access)]
        }

        private static func client(of signature: Interface.Analysis, access: String) -> DeclSyntax {
            let owner = signature.owner.trimmedDescription
            let operations = Interface.Derivation.operations(of: signature)
            let storedArrows = operations.map { operation in
                "    private let _\(operation.caseName): \(arrow(of: operation, owner: owner))"
            }
            let storedChildren = signature.children.map { child in
                "    \(access)let \(child.name.text): \(child.domain.trimmedDescription).Client<External>"
            }
            let parameters = operations.map { operation in
                "\(operation.caseName): \(arrow(of: operation, owner: owner))"
            } + signature.children.map { child in
                "\(child.name.text): \(child.domain.trimmedDescription).Client<External>"
            }
            let assignments = operations.map { operation in
                "        self._\(operation.caseName) = \(operation.caseName)"
            } + signature.children.map { child in
                "        self.\(child.name.text) = \(child.name.text)"
            }
            let forwarding = operations.map { operation in
                let coordinate = operation.coordinate
                return """
                    \(access)func \(operation.name)\(coordinate.declaration.signature.parameterClause.trimmedDescription) async throws(\(failure(of: operation))) -> \(operation.output) {
                        try await self._\(operation.caseName)(\(operation.requestPath(owner: owner))(\(operation.construction)))
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

        private static func failure(of operation: Interface.Derivation.Operation) -> String {
            "Either<External, \(operation.coordinate.failure.trimmedDescription)>"
        }

        private static func arrow(of operation: Interface.Derivation.Operation, owner: String) -> String {
            "Client::Client<\(operation.requestPath(owner: owner)), \(operation.output), \(failure(of: operation))>"
        }
    }
}
