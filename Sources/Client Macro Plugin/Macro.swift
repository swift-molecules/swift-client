import Client_Macro_Core
import Interface_Macro_Core
import SwiftSyntax
import SwiftSyntaxMacros

public struct Macro: PeerMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = declaration.as(ProtocolDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@Client applies to a protocol declaration only.")
        }
        let owner = context.lexicalContext.first.flatMap { syntax -> TypeSyntax? in
            if let declaration = syntax.as(EnumDeclSyntax.self) {
                return TypeSyntax(IdentifierTypeSyntax(name: declaration.name))
            }
            if let declaration = syntax.as(StructDeclSyntax.self) {
                return TypeSyntax(IdentifierTypeSyntax(name: declaration.name))
            }
            if let declaration = syntax.as(ExtensionDeclSyntax.self) {
                return declaration.extendedType.trimmed
            }
            return nil
        }
        let spelling = declaration.name.text
        let name = spelling.first == "`" && spelling.last == "`"
            ? String(spelling.dropFirst().dropLast())
            : spelling
        guard name == "Protocol" || name == "Interface", let owner else {
            throw MacroExpansionErrorMessage(
                "@Client requires the interface's semantic protocol (`Interface` or `Protocol`) nested in its owner."
            )
        }
        let signature = Interface.Analysis(declaration: declaration, owner: owner)
        guard signature.diagnostics.isEmpty else {
            throw MacroExpansionErrorMessage(
                "@Client cannot derive this finite signature: \(signature.diagnostics.joined(separator: "; "))."
            )
        }
        return Client.Derivation.peers(of: signature)
    }
}
