import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

import Foundation

public enum DependencyProviderMacro: MemberMacro {
    public static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self),
              let view = structDecl.inheritanceClause?.inheritedTypes.first?.type.as(IdentifierTypeSyntax.self),
              view.name.text == "View" else {
            throw DependencyMacroError.typeMismatch("Provider macro can only be installed on a view.")
        }
        
        guard case .argumentList(let arguments) = node.arguments else {
            throw DependencyMacroError.argumentTypeMismatch("Provider requires at least one dependency.")
        }
        
        guard let first = arguments.first, first.expression.is(KeyPathExprSyntax.self) else {
            throw DependencyMacroError.argumentTypeMismatch("Provider requires a variadic list of valid KeyPaths descending from Dependencies.")
        }
        
        let dependencyKeys = arguments
            .compactMap { arg -> String? in
                if let keyPathExpr = arg.expression.as(KeyPathExprSyntax.self),
                   let firstComponent = keyPathExpr.components.first?.component.as(KeyPathPropertyComponentSyntax.self) {
                    return firstComponent.declName.baseName.text
                } else {
                    return nil
                }
            }
        
        let customNames = arguments
            .filter { $0.label?.text == "name" }
            .map { $0.expression
                    .as(StringLiteralExprSyntax.self)?
                    .segments.first?
                    .as(StringSegmentSyntax.self)?.content.text
            }
        
        var observed = false
        if let boolExpr = arguments.first(labeled: "observed")?.expression.as(BooleanLiteralExprSyntax.self),
           boolExpr.literal.text == "true" {
            observed = true
        }
        
        return dependencyKeys.enumerated()
            .map { ($0.1, customNames[safe: $0.0] ?? nil, observed) }
            .compactTryMap(provideSyntax)
    }
    
    private static func provideSyntax(for dependencyKey: String, variableName: String?, observed: Bool) throws -> DeclSyntax {
        var syntax = try VariableDeclSyntax("private var \(raw: variableName ?? dependencyKey) = Dependencies.shared.\(raw: dependencyKey)")
        if observed {
            syntax.attributes = "@ObservedObject"
        }
        return DeclSyntax(syntax)
    }
}

public enum DependencyEntryMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let variableDecl = declaration.as(VariableDeclSyntax.self),
              let patternBinding = variableDecl.bindings.first,
              let identifierPattern = patternBinding.pattern.as(IdentifierPatternSyntax.self) else {
            throw DependencyMacroError.typeMismatch("Provide macro only works on variables.")
        }
        
        guard let parentExtension = context.lexicalContext.first?.as(ExtensionDeclSyntax.self),
              let extensionIdentifier = parentExtension.extendedType.as(IdentifierTypeSyntax.self),
              ["Dependencies", "DependencyContainer"].contains(extensionIdentifier.name.text) else {
            throw DependencyMacroError.parentTypeMismatch("Provide macro should be used inside an extension block of Dependencies.")
        }
        
        var defaultValue: ExprSyntax = .init(NilLiteralExprSyntax())
        let variableName = identifierPattern.identifier.text
        
        if let initializer = patternBinding.initializer {
            defaultValue = initializer.value
        }
        
        return [
            "get { self[\"\(raw: variableName)\", default: \(defaultValue)] }",
            "set { self[\"\(raw: variableName)\"] = newValue }"
        ]
    }
}

public enum DependencyResolverMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard node.arguments.count <= 1 else {
            throw DependencyMacroError.argumentTypeMismatch("Too many arguments. Only one accepted.")
        }
        guard let keyPathExpr = node.arguments.first?.expression.as(KeyPathExprSyntax.self),
              let component = keyPathExpr.components.first?.component.as(KeyPathPropertyComponentSyntax.self) else {
            throw DependencyMacroError.argumentTypeMismatch("resolve macro requires at least one keypath descending from Dependencies.")
        }
        
        let componentName = component.declName.baseName.text
        
        return "Dependencies.shared.\(raw: componentName)"
    }
}

public enum DependencyInjectorMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let keyPathExpr = node.arguments.first?.expression.as(KeyPathExprSyntax.self),
              let component = keyPathExpr.components.first?.component.as(KeyPathPropertyComponentSyntax.self) else {
            throw DependencyMacroError.argumentTypeMismatch("Inject macro requires at least one keypath descending from Dependencies.")
        }
        
        let componentName = component.declName.baseName.text
        var variableName = componentName
        
        if let stringExpr = node.arguments.first(labeled: "name")?.expression.as(StringLiteralExprSyntax.self),
           let providedName = stringExpr.segments.first?.as(StringSegmentSyntax.self)?.content.text {
            variableName = providedName
        }
        
        var observed = false
        if let boolExpr = node.arguments.first(labeled: "observed")?.expression.as(BooleanLiteralExprSyntax.self),
           boolExpr.literal.text == "true" {
            observed = true
        }
        
        var variableDeclSyntax = try VariableDeclSyntax("private var \(raw: variableName) = Dependencies.shared.\(raw: componentName)")
        if observed {
            variableDeclSyntax.attributes = "@ObservedObject"
        }
        
        return [DeclSyntax(variableDeclSyntax)]
    }
}

// MARK: - Error
enum DependencyMacroError: LocalizedError, CustomStringConvertible {
    case typeMismatch(String)
    case parentTypeMismatch(String)
    case argumentTypeMismatch(String)
    case variableNameRequired
    
    var description: String {
        switch self {
        case .typeMismatch(let message): "Type Mismatch: \(message)"
        case .parentTypeMismatch(let message): "Parent Type Mismatch: \(message)"
        case .argumentTypeMismatch(let message): "Argument Type Mismatch: \(message)"
        case .variableNameRequired: "Variable Name Required."
        }
    }
    
    var errorDescription: String? { description }
}

// MARK: - Private extensions
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

private extension Sequence {
    func tryMap<ElementOfResult>(_ transform: @escaping (Element) throws -> ElementOfResult) rethrows -> [ElementOfResult] {
        try reduce(into: [ElementOfResult]()) { partialResult, element in
            partialResult.append(try transform(element))
        }
    }
    
    func compactTryMap<ElementOfResult>(_ transform: @escaping (Element) throws -> ElementOfResult) -> [ElementOfResult] {
        reduce(into: [ElementOfResult]()) { partialResult, element in
            if let elementOfResult = try? transform(element) {
                partialResult.append(elementOfResult)
            }
        }
    }
}
