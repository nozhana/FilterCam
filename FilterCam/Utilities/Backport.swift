//
//  Backport.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/20/25.
//

import SwiftUI

@propertyWrapper
struct Backport<V> {
    var wrappedValue: V
    
    init(wrappedValue: V) {
        self.wrappedValue = wrappedValue
    }
    
    init(_ value: V) {
        self.wrappedValue = value
    }
}

extension View {
    var backport: Backport<Self> { .init(self) }
}

extension Backport where V: View {
    @ViewBuilder
    func onCameraCaptureEvent(perform action: @escaping () -> Void) -> some View {
        if #available(iOS 18.0, *) {
            wrappedValue.onCameraCaptureEvent { event in
                if event.phase == .ended {
                    action()
                }
            }
        } else if #available(iOS 17.2, *) {
            wrappedValue.background(
                CameraInteractiveView(onCapture: action)
            )
        } else {
            wrappedValue
        }
    }
    
    @ViewBuilder
    func onCameraCaptureEvent(primaryAction: @escaping () -> Void, secondaryAction: @escaping () -> Void) -> some View {
        if #available(iOS 18.0, *) {
            wrappedValue.onCameraCaptureEvent { event in
                if event.phase == .ended {
                    primaryAction()
                }
            } secondaryAction: { event in
                if event.phase == .ended {
                    secondaryAction()
                }
            }
        } else if #available(iOS 17.2, *) {
            wrappedValue.background(
                CameraInteractiveView(onCapture: primaryAction)
            )
        } else {
            wrappedValue
        }
    }
    
    @ViewBuilder
    func matchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            wrappedValue.matchedTransitionSource(id: id, in: namespace)
        } else {
            wrappedValue
        }
    }
    
    @ViewBuilder
    func navigationTransitionZoom(sourceID: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            wrappedValue.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            wrappedValue
        }
    }
}
 
extension Backport where V: View {
    struct ScrollGeometry : Equatable, Sendable {
        var contentOffset: CGPoint
        var contentSize: CGSize
        var contentInsets: EdgeInsets
        var containerSize: CGSize
        var visibleRect: CGRect
        var bounds: CGRect
    }
    
    @ViewBuilder
    func onScrollGeometryChange<Value>(for valueType: Value.Type, of keyPath: @escaping (ScrollGeometry) -> Value, action: @escaping (_ oldValue: Value, _ newValue: Value) -> Void) -> some View where Value: Equatable {
        if #available(iOS 18.0, *) {
            wrappedValue.onScrollGeometryChange(for: Value.self, of: { keyPath(.init($0)) }, action: action)
        } else {
            wrappedValue
        }
    }
}

extension Backport.ScrollGeometry {
    @available(iOS 18.0, *)
    init(_ geometry: SwiftUI.ScrollGeometry) {
        self.init(contentOffset: geometry.contentOffset, contentSize: geometry.contentSize, contentInsets: geometry.contentInsets, containerSize: geometry.containerSize, visibleRect: geometry.visibleRect, bounds: geometry.bounds)
    }
}

extension ViewAlignedScrollTargetBehavior.LimitBehavior {
    static var backport: Backport<Self> { .init(.automatic) }
}

extension Backport where V == ViewAlignedScrollTargetBehavior.LimitBehavior {
    var alwaysByOne: V {
        if #available(iOS 18.0, *) {
            .alwaysByOne
        } else {
            .always
        }
    }
}
