import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum SlopeSubsetError: CustomStringConvertible, Error {
    case onlyApplicableToEnum
    case failtToDeterminGenericType
    
    var description: String {
        switch self {
        case .onlyApplicableToEnum:
            return "@EnumSubsetはenumにだけ使えます"
        case .failtToDeterminGenericType:
            return "型がわかりません"
        }
    }
}

public struct SlopeSubsetMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw SlopeSubsetError.onlyApplicableToEnum
        }
        
        guard let supersetType = node
            .attributeName.as(IdentifierTypeSyntax.self)?
            .genericArgumentClause?
            .arguments.first?
            .argument else {
            throw SlopeSubsetError.failtToDeterminGenericType
        }
        
        let members = enumDecl.memberBlock.members
        let caseDecls = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let elements = caseDecls.flatMap { $0.elements }
        
        let inisializer = try InitializerDeclSyntax("init?(_ slope: \(supersetType))") {
            try SwitchExprSyntax("switch slope") {
                for element in elements {
                    SwitchCaseSyntax(
                        """
                        case .\(element.name):
                            self = .\(element.name)
                        """
                    )
                }
                SwitchCaseSyntax("default: return nil")
            }
        }
        
        return [DeclSyntax(inisializer)]
    }
}


@main
struct SampleMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SlopeSubsetMacro.self
    ]
}
