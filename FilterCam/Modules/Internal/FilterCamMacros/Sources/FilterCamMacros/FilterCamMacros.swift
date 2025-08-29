// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: arbitrary)
@attached(extension, conformances: OptionSet)
public macro OptionSetBuilder<RawType>() = #externalMacro(module: "FilterCamMacrosInternal", type: "OptionSetMacro")

#if canImport(FilterCamBase)
import FilterCamBase

@attached(member, names: arbitrary)
public macro Provider(_ keyPaths: PartialKeyPath<Dependencies>..., name: String..., observed: Bool = false) = #externalMacro(module: "FilterCamMacrosInternal", type: "DependencyProviderMacro")

@freestanding(expression)
public macro resolve<T>(_ keyPath: KeyPath<Dependencies, T>) -> T = #externalMacro(module: "FilterCamMacrosInternal", type: "DependencyResolverMacro")

@freestanding(declaration, names: arbitrary)
public macro Inject(_ keyPath: PartialKeyPath<Dependencies>, name: String? = nil, observed: Bool = false) = #externalMacro(module: "FilterCamMacrosInternal", type: "DependencyInjectorMacro")

@attached(accessor)
public macro Provide() = #externalMacro(module: "FilterCamMacrosInternal", type: "DependencyEntryMacro")
#endif
