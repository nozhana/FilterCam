import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FilterCamMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        OptionSetMacro.self,
        DependencyProviderMacro.self,
        DependencyEntryMacro.self,
        DependencyResolverMacro.self,
    ]
}
