//
//  FilterChainCreatorView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import AVFoundation
import Combine
import FilterCamBase
import FilterCamMacros
import GPUImage
import SwiftUI

@Provider(\.database)
@Provider(\.cameraModel, observed: true)
struct FilterChainCreatorView: View {
    @StateObject private var model = Model()
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    
    @State private var controlPanelDetent = PresentationDetent.medium
    
    var body: some View {
        NavigationStack {
            switch model.status {
            case .unknown:
                ContentUnavailableView("Unknown status", systemImage: "questionmark.circle.dashed")
            case .loading:
                ProgressView("Loading")
                    .font(.title2.bold())
            case .unauthorized:
                ContentUnavailableView("Unauthorized", systemImage: "eye.slash.fill", description: Text("Please allow access in Settings to use the camera."))
                    .safeAreaInset(edge: .bottom, spacing: 16) {
                        Link(destination: .appSettingsOrGeneralSettings) {
                            Label("App Settings", systemImage: "arrow.up.right")
                        }
                    }
            case .failed(let error):
                ContentUnavailableView("Failed to load view", systemImage: "exclamationmark.triangle.fill", description: Text("Failed to initialize Filter Chain Creator.").foregroundStyle(.secondary))
                    .safeAreaInset(edge: .bottom, spacing: 16) {
                        if let error {
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.red)
            case .running:
                MetalRenderView(previewTarget: model.target)
                    .overlay(.ultraThinMaterial.opacity(model.isPaused ? 1 : 0))
                    .ignoresSafeArea()
                    .scaledToFill()
                    .containerRelativeFrame(.vertical, count: 2, span: model.showControlPanel && controlPanelDetent == .medium ? 1 : 2, spacing: .zero)
                    .containerRelativeFrame(.horizontal)
                    .clipped()
                    .frame(maxHeight: .infinity, alignment: .top)
                    .overlay(alignment: .bottomTrailing) {
                        HStack(spacing: 24) {
                            Button {
                                withAnimation(.smooth) {
                                    model.showControlPanel = true
                                }
                            } label: {
                                Image(systemName: "camera.filters")
                                    .font(.title3.bold())
                                    .padding(16)
                                    .background(.background.tertiary.opacity(0.5), in: .circle)
                            }
                            .foregroundStyle(Color.primary)
                            if !model.filters.isEmpty {
                                Button {
                                    withAnimation(.smooth) {
                                        do {
                                            try model.save(on: database, cameraModel: cameraModel)
                                            dismiss()
                                        } catch {}
                                    }
                                } label: {
                                    Image(systemName: "square.and.arrow.down.fill")
                                        .font(.title3.bold())
                                        .padding(16)
                                        .background(Color.accentColor.gradient.secondary.opacity(0.5), in: .circle)
                                        .background(.ultraThinMaterial, in: .circle)
                                }
                                .foregroundStyle(Color.primary)
                            }
                        }
                        .padding(24)
                    }
                    .sheet(isPresented: $model.showControlPanel) {
                        FilterChainControlPanelView(model: model) {
                            do {
                                try model.save(on: database, cameraModel: cameraModel)
                                dismiss()
                            } catch {}
                        }
                        .presentationDetents([.medium, .large], selection: $controlPanelDetent)
                    }
            }
        }
        .task(id: scenePhase) {
            withAnimation(.smooth) {
                model.isPaused = scenePhase != .active
            }
        }
    }
}

private extension FilterChainCreatorView {
    final class Model: ObservableObject {
        typealias Source = PreviewSource & ImageSource
        
        @Published var filters: [CameraFilter] = []
        @Published var isPaused = false
        @Published var showControlPanel = false
        @Published private(set) var status = Status.unknown
        
        let target: MetalPreviewTarget
        
        private let captureService: CaptureService!
        private let previewSource: Source!
        private let filterChain: FilterChain
        
        private var cancellables = Set<AnyCancellable>()
        
        init() {
            target = .metal()
            filterChain = []
            status = .loading
            do {
                let cameraSource = try MetalCameraSource()
                previewSource = cameraSource
                captureService = CaptureService(previewSource: cameraSource, previewTarget: filterChain, photoOutput: .metal(), movieOutput: .metal(), session: cameraSource.session)
                
                observeState()
                Task { await setup() }
            } catch {
                logger.error("Failed to create capture service: \(error)")
                status = .failed(error)
                previewSource = nil
                captureService = nil
            }
        }
        
        func operation(for filter: CameraFilter) -> ImageProcessingOperation? {
            filterChain.filters[filter]
        }
        
        @MainActor
        func save(on database: DatabaseService, cameraModel: some CameraModelProtocol) throws {
            let filtersCount = (try? database.count(CustomFilter.self)) ?? 0
            let filterIndex = (try? database.max(CustomFilter.self, by: \.layoutIndex)).map { $0.layoutIndex + 1 } ?? 0
            
            for (offset, filter) in filters.enumerated() {
                for configuration in filter.configurations {
                    switch configuration {
                    case .slider(let title, _, _, let bindingFactory):
                        let index = filter.configurations.filter(\.isSlider).firstIndex(where: { $0.title == title }) ?? 0
                        if let operation = filterChain.filters[filter] {
                            let value = bindingFactory(operation).wrappedValue
                            filters[offset].update(with: value, atIndex: index)
                        }
                    case .toggle(let title, let bindingFactory):
                        let index = filter.configurations.filter(\.isToggle).firstIndex(where: { $0.title == title }) ?? 0
                        if let operation = filterChain.filters[filter] {
                            let value = bindingFactory(operation).wrappedValue
                            filters[offset].update(with: value, atIndex: index)
                        }
                    case .button:
                        break
                    }
                }
            }
            let filter = CustomFilter(title: "My Filter \(filtersCount + 1)", layoutIndex: filterIndex, filterConfiguration: filters)
            do {
                try database.save(filter)
                filters.removeAll()
                if let filterStack = cameraModel.previewTarget as? FilterStack {
                    filterStack.addTarget(for: .custom(filter))
                    withAnimation(.smooth) {
                        cameraModel.lastFilter = .custom(filter)
                    }
                }
            } catch {
                logger.error("Failed to save custom filter: \(String(describing: filter))")
                throw error
            }
        }
        
        @MainActor
        private func setup() async {
            guard await captureService.isAuthorized else {
                status = .unauthorized
                return
            }
            
            filterChain.removeAllTargets()
            filterChain.reset(with: filters)
            filterChain.addTarget(target)
            do {
                try await captureService.start(with: .logging)
                status = .running
            } catch {
                logger.error("Failed to start capture service: \(error)")
                status = .failed(error)
            }
        }
        
        private func observeState() {
            $filters
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newFilters in
                    guard let self else { return }
                    if filterChain.filters.count != newFilters.count {
                        filterChain.reset(with: newFilters)
                    }
                }
                .store(in: &cancellables)
            
            $isPaused
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] paused in
                    guard let camera = self?.previewSource as? MetalCameraSource else { return }
                    if paused {
                        camera.stop()
                    } else {
                        camera.start()
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    enum Status {
        case unknown, loading, unauthorized, failed(Error? = nil), running
        
        static let failed = failed()
    }
}

private struct FilterChainControlPanelView: View {
    @ObservedObject var model: FilterChainCreatorView.Model
    var saveFilter: () -> Void
    
    @State private var filterConfigurationsExpanded: [CameraFilter: Bool] = [:]
    
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    addFilterButton
                }
                Section {
                    ForEach(model.filters.enumerated().map(\.self), id: \.offset) { (offset, filter) in
                        let binding = Binding {
                            filterConfigurationsExpanded[filter] ?? false
                        } set: {
                            filterConfigurationsExpanded[filter] = $0
                        }
                        
                        VStack(alignment: .leading) {
                            Button(filter.title, systemImage: binding.wrappedValue ? "chevron.up" : "chevron.down") {
                                withAnimation(.smooth) {
                                    binding.wrappedValue.toggle()
                                }
                            }
                            .contentTransition(.symbolEffect)
                            
                            if binding.wrappedValue,
                               let operation = model.operation(for: filter) {
                                FilterConfiguratorView(filter: filter, operation: operation)
                            }
                        }
                    }
                    .onMove { fromOffsets, toOffset in
                        model.filters.move(fromOffsets: fromOffsets, toOffset: toOffset)
                    }
                    .onDelete { indexSet in
                        var filters = model.filters
                        for index in indexSet {
                            filters.remove(at: index)
                        }
                        withAnimation(.smooth) {
                            model.filters = filters
                        }
                    }
                } header: {
                    Label("Filters", systemImage: "camera.filters")
                }

            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    EditButton()
                        .onChange(of: editMode?.wrappedValue.isEditing == true) { _, isEditing in
                            if isEditing {
                                withAnimation(.smooth) {
                                    for filter in model.filters {
                                        filterConfigurationsExpanded[filter] = true
                                    }
                                }
                            }
                        }
                    if !model.filters.isEmpty {
                        Button("Save", systemImage: "square.and.arrow.down.fill") {
                            saveFilter()
                        }
                    }
                }
            }
            .navigationTitle("Filters")
        }
    }
    
    private var addFilterButton: some View {
        Menu("Add Filter", systemImage: "plus.circle.fill") {
            Section("General Filters") {
                let filters = [CameraFilter.noir, .blur(), .haze(), .sepia(), .sharpen()]
                    .filter { !model.filters.contains($0) }
                
                ForEach(filters, id: \.self) { filter in
                    Button(filter.title, systemImage: "camera.filters") {
                        model.filters.append(filter)
                    }
                }
            }
            Section("Lookup Filters") {
                let lookupFilters = CameraFilter.LookupImage.allCases.map { CameraFilter.lookup(image: $0) }
                let filters = lookupFilters.filter { !model.filters.contains($0) }
                ForEach(filters, id: \.self) { filter in
                    Button(filter.title, systemImage: "camera.filters") {
                        model.filters.append(filter)
                    }
                }
            }
        }
    }
}
