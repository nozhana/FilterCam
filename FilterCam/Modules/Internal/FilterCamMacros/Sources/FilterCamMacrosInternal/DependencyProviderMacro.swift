import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

import FilterCamBase
import Foundation

public struct DependencyProviderMacro: MemberMacro {
    public static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self),
              let view = structDecl.inheritanceClause?.inheritedTypes.first?.type.as(IdentifierTypeSyntax.self),
              view.name.text == "View" else {
            throw DependencyProviderMacroError.typeMismatch("DependencyProvider macro can only be installed on a view.")
        }
        
        guard case .argumentList(let arguments) = node.arguments else {
            throw DependencyProviderMacroError.argumentTypeMismatch("DependencyProvider requires at least one dependency.")
        }
        
        guard arguments.first?.expression.is(MemberAccessExprSyntax.self) == true else {
            throw DependencyProviderMacroError.argumentTypeMismatch("DependencyProvider requires a variadic list of `Dependency` cases.")
        }
        
        let dependencies = arguments
            .compactMap { $0.expression.as(MemberAccessExprSyntax.self) }
            .map { $0.declName.baseName.text }
            .compactMap { Dependency(rawValue: $0) }
        
        let customNames = arguments
            .filter { $0.label?.text == "name" }
            .map { $0.expression
                    .as(StringLiteralExprSyntax.self)?
                    .segments.first?
                    .as(StringSegmentSyntax.self)?.content.text
            }
        
        let create: Bool
        if let boolExpr = arguments.first(labeled: "create")?.expression.as(BooleanLiteralExprSyntax.self) {
            switch boolExpr.literal.text {
            case "true":
                create = true
            default:
                create = false
            }
        } else {
            create = false
        }
        
        return dependencies.enumerated()
            .map { ($0.1, customNames[safe: $0.0] ?? nil, create) }
            .map(provideSyntax)
    }
    
    private static func provideSyntax(for dependency: Dependency, variableName: String?, create: Bool) -> DeclSyntax {
        return switch dependency {
        case .cameraModel: """
#if DEBUG && targetEnvironment(simulator)
@StateObject private var \(raw: variableName ?? "model") = MockCameraModel()
#else
\(raw: create ? """
@StateObject private var \(variableName ?? "model") = CameraModel()
""" : """
@EnvironmentObject private var \(variableName ?? "model"): CameraModel
""")
#endif
"""
        case .database: """
@Environment(\\.database) private var \(raw: variableName ?? "database")
"""
        case .mediaStore: """
@Environment(\\.mediaStore) private var \(raw: variableName ?? "mediaStore")
"""
        }
    }
}

enum DependencyProviderMacroError: LocalizedError, CustomStringConvertible {
    case typeMismatch(String)
    case argumentTypeMismatch(String)
    
    var description: String {
        switch self {
        case .typeMismatch(let message): "Type Mismatch: \(message)"
        case .argumentTypeMismatch(let message): "Argument Type Mismatch: \(message)"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        get { indices.contains(index) ? self[index] : nil }
        set {
            if let newValue, indices.contains(index) {
                self[index] = newValue
            }
        }
    }
}
