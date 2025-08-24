//
//  ToasterContainerModifier.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import simd
import SwiftUI

struct ToasterContainerModifier: ViewModifier {
    @ObservedObject var toaster: Toaster
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    ForEach(toaster.toasts.enumerated().map(\.self), id: \.offset) { (offset, toast) in
                        let interpolation: CGFloat = simd_smoothstep(-1, Double(toaster.toasts.count-1), Double(offset))
                        let scale: CGFloat = 0.8.interpolated(towards: 1.0, amount: interpolation)
                        let offset: CGFloat = (16 * Double(toaster.toasts.count)).interpolated(towards: 0, amount: interpolation)
                        ToastView(toast: toast)
                            .scaleEffect(scale, anchor: .bottom)
                            .offset(y: offset)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    toaster.removeToast(toast)
                                }
                            }
                    }
                }
                .safeAreaPadding(.horizontal, 20)
            }
            .environmentObject(toaster)
    }
}

private struct ToastView: View {
    var toast: Toast
    
    var body: some View {
        HStack(spacing: 16) {
            toast.icon?
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(.primary.opacity(0.75))
            toast.message
                .font(.callout.weight(.medium))
                .foregroundStyle(.primary.opacity(0.75))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .ifLet(toast.tint) { content, tint in
            content
                .background(tint.gradient.tertiary, in: .rect(cornerRadius: 12))
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
        } else: { content in
            content
                .background(.background.secondary, in: .rect(cornerRadius: 12))
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.separator.secondary, lineWidth: 2)
        }
    }
}

extension View {
    func toasterContainer(_ toaster: Toaster = .shared) -> some View {
        modifier(ToasterContainerModifier(toaster: toaster))
    }
}

#Preview {
    @Previewable @ObservedObject var toaster = Toaster.shared
    
    NavigationStack {
        ScrollView {
            VStack {
                ForEach(0..<10) { index in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.background.secondary)
                        .aspectRatio(4.0/3, contentMode: .fit)
                        .overlay {
                            Text("\(index)")
                                .font(.title2.bold())
                        }
                }
            }
        }
        .contentMargins(20, for: .scrollContent)
        .navigationTitle("Example")
    }
    .toasterContainer(toaster)
    .task {
        for index in 0..<5 {
            try? await Task.sleep(for: .seconds(0.5))
            toaster.showToast("Sending love, index \(index)")
        }
    }
}
