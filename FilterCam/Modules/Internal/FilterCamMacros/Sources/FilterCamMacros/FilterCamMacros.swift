// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: arbitrary)
@attached(extension, conformances: OptionSet)
public macro OptionSetBuilder<RawType>() = #externalMacro(module: "FilterCamMacrosInternal", type: "OptionSetMacro")

#if canImport(FilterCamBase)
import FilterCamBase

@attached(member, names: arbitrary)
public macro DependencyProvider(_ keyPaths: PartialKeyPath<Dependencies>..., name: String..., observed: Bool = false) = #externalMacro(module: "FilterCamMacrosInternal", type: "DependencyProviderMacro")
#endif

@attached(accessor)
public macro Provide() = #externalMacro(module: "FilterCamMacrosInternal", type: "DependencyEntryMacro")
