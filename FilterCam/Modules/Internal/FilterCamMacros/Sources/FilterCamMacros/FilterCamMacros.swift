// The Swift Programming Language
// https://docs.swift.org/swift-book

import FilterCamBase

@attached(member, names: arbitrary)
@attached(extension, conformances: OptionSet)
public macro OptionSetBuilder<RawType>() = #externalMacro(module: "FilterCamMacrosInternal", type: "OptionSetMacro")

@attached(member, names: arbitrary)
public macro DependencyProvider(_ dependency: Dependency, _ dependencies: Dependency..., name: String..., create: Bool = false) = #externalMacro(module: "FilterCamMacrosInternal", type: "DependencyProviderMacro")
