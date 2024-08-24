//
//  ContentView.swift
//  Playground
//
//  Created by Alex Fargo on 8/7/24.
//

import SwiftUI

struct SheetBackgroundStyle: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        if environment.colorScheme == .dark {
            return AnyShapeStyle(.background.secondary)
        }
        
        return AnyShapeStyle(.background)
    }
}

extension ShapeStyle where Self == SheetBackgroundStyle {
    static var sheetBackground: SheetBackgroundStyle {
        SheetBackgroundStyle()
    }
}

struct SheetBackgroundViewModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    var isFullScreen: Bool
    var cornerRadius: Double
    
    private var shadowEnabled: Bool {
        colorScheme != .dark
    }
    
    private var shadowOpacity: Double {
        isFullScreen ? 0.0 : 0.24
    }
    
    private var sheetBackground: some ShapeStyle {
        if shadowEnabled {
            return AnyShapeStyle(
                .background.shadow(
                    .drop(
                        color: .gray.opacity(shadowOpacity),
                        radius: 10
                    )
                )
            )
        } else {
            return AnyShapeStyle(.background)
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                Color.clear
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: cornerRadius,
                            style: .continuous
                        )
                        .strokeBorder(.background.secondary.opacity(isFullScreen ? 0 : 1), lineWidth: 1)
                    }
                    .background(
                        sheetBackground,
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
                    .ignoresSafeArea(isFullScreen ? .all : .keyboard)
            }
            .backgroundStyle(.sheetBackground)
    }
}

extension View {
    func sheetBackground(isFullScreen: Bool) -> some View {
        modifier(SheetBackgroundViewModifier(isFullScreen: isFullScreen, cornerRadius: 32))
    }
}

struct ContentView: View {
    @State private var showingSheet = false
    @State private var isFullScreen = false
    
    var buttonTransition: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }
    
    var sheetTransition: AnyTransition {
        .scale(scale: 0.1, anchor: .bottom).combined(with: .opacity)
    }
    
    var body: some View {
        ZStack {
            if !showingSheet {
                Button {
                    withAnimation(.snappy(duration: 0.35, extraBounce: 0.1)) {
                        showingSheet = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .foregroundStyle(.primary)
                .transition(buttonTransition)
            } else {
                VStack {
                    SheetContentView(isFullScreen: $isFullScreen)
                        .frame(maxWidth: isFullScreen ? .infinity : nil, maxHeight: isFullScreen ? .infinity : nil)
                }
                .safeAreaInset(
                    edge: .top,
                    alignment: .trailing,
                    spacing: 0
                ) {
                    Button {
                        withAnimation(.snappy(duration: 0.35, extraBounce: 0.1)) {
                            isFullScreen = false
                            showingSheet = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.small)
                            .padding(8)
                            .background(
                                .background.secondary,
                                in: .circle
                            )
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.top, isFullScreen ? 4 : 16)
                }
                .transition(sheetTransition)
            }
        }
        .sheetBackground(isFullScreen: isFullScreen)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .bottom
        )
        .padding(.all, isFullScreen ? 0 : nil)
    }
}

struct KeypadButtonStyle: ButtonStyle {
    var scaleWithPress: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(
                backgroundStyle(for: configuration),
                in: .rect(cornerRadius: 8)
            )
            .contentShape(.rect(cornerRadius: 8))
            .scaleEffect(scale(for: configuration))
    }
    
    func backgroundStyle(for configuration: Configuration) -> some ShapeStyle {
        .background.secondary.opacity(configuration.isPressed ? 1 : 0)
    }
    
    func scale(for configuration: Configuration) -> CGFloat {
        guard scaleWithPress else { return 1 }
        return configuration.isPressed ? 1.1 : 1
    }
}

extension ButtonStyle where Self == KeypadButtonStyle {
    static var keypadButton: KeypadButtonStyle {
        KeypadButtonStyle()
    }
}

struct SheetContentView: View {
    @State private var amountText: String = "0"
    @Binding var isFullScreen: Bool
    @FocusState private var sheetDetailIsFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text("$" + amountText)
                .font(.largeTitle)
                .bold()
            
            if !isFullScreen {
                Button {
                    withAnimation {
                        isFullScreen.toggle()
                    }
                } label: {
                    Text("Add Details")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                .transition(.opacity.animation(.snappy(duration: 0.3)))
            } else {
                SheetDetailsView()
                    .focused($sheetDetailIsFocused)
                
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                if !sheetDetailIsFocused {
                    KeypadView(handleButtonTap: handleButtonTap(_:))
                        .transition(.opacity)
                }
                
                Button {
                    
                } label: {
                    Text("Add")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background {
                            Capsule()
                                .fill(Color.blue)
                        }
                        .foregroundStyle(.white)
                }
            }
        }
        .animation(.default, value: sheetDetailIsFocused)
        .padding()
    }
    
    func handleButtonTap(_ button: KeypadView.KeypadButton) {
        switch button {
        case .number(let number):
            guard let amountNumber = Double(amountText) else { return }
            if amountNumber == 0 { amountText = String(number) }
            else { amountText += String(number) }
        case .operation(let operation):
            switch operation {
            case .decimal:
                guard
                    !amountText.contains(where: { $0 == "." }),
                    !amountText.isEmpty
                else { return }
                amountText += "."
            case .delete:
                guard amountText.count > 0 else { return }
                _ = amountText.removeLast()
                guard let amountNumber = Double(amountText) else {
                    amountText = "0"
                    return
                }
                if amountNumber == 0 { amountText = "0" }
            }
        }
    }
}

struct KeypadView: View {
    enum KeypadButton: View {
        enum Operation {
            case delete
            case decimal
        }
        
        case number(Int)
        case operation(Operation)
        
        var body: some View {
            switch self {
            case .number(let number):
                numberBody(number)
            case .operation(let operation):
                operationBody(operation)
            }
        }
        
        @ViewBuilder
        private func numberBody(_ number: Int) -> some View {
            Text("\(number)")
        }
        
        @ViewBuilder
        private func operationBody(_ operation: Operation) -> some View {
            switch operation {
            case .delete:
                Image(systemName: "delete.backward")
            case .decimal:
                Text(".")
            }
        }
    }
    
    var buttons: [[KeypadButton]] = [
        [.number(1), .number(2), .number(3)],
        [.number(4), .number(5), .number(6)],
        [.number(7), .number(8), .number(9)],
        [.operation(.decimal), .number(0), .operation(.delete)]
    ]
    
    var handleButtonTap: ((KeypadButton) -> Void)
    
    var body: some View {
        Grid {
            ForEach(buttons.indices, id: \.self) { row in
                GridRow {
                    ForEach(buttons[row].indices, id: \.self) { col in
                        Button {
                            handleButtonTap(buttons[row][col])
                        } label: {
                            buttons[row][col]
                                .font(.system(size: 20))
                                .frame(maxWidth: .infinity)
                                .padding(12)
                        }
                        .buttonStyle(.keypadButton)
                    }
                }
            }
        }
    }
}

struct SheetDetailRowViewModifier: ViewModifier {
    let rowHeight: CGFloat = 50
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(height: rowHeight)
            .background(.background.secondary)
            .background(in: .rect(cornerRadius: 12))
    }
}

extension View {
    func sheetDetailRow() -> some View {
        modifier(SheetDetailRowViewModifier())
    }
}

struct MenuLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == MenuLabelStyle {
    static var menuLabel: MenuLabelStyle { .init() }
}

struct SheetDetailsView: View {
    enum TransactionType: String, CaseIterable, Identifiable, CustomStringConvertible {
        case income
        case expense
        
        var id: Self { self }
        
        var description: String { rawValue.capitalized }
    }
    
    enum TransactionCategory: String, CaseIterable, Identifiable, CustomStringConvertible {
        case none
        case food
        case entertainment
        case clothing
        case transportation
        case health
        case other
        
        var id: Self { self }
        
        var description: String { rawValue.capitalized }
    }
    
    @State private var name: String = ""
    @State private var type: TransactionType = .income
    @State private var category: TransactionCategory = .none
    @State private var date: Date = .now
    @FocusState private var focus: Bool
    
    var body: some View {
        VStack {
            TextField("Enter name...", text: $name)
                .focused($focus)
                .multilineTextAlignment(.center)
                .sheetDetailRow()
            
            PickerRow(
                systemImage: "plus.square",
                title: "Type",
                selection: $type
            ) {
                ForEach(TransactionType.allCases, id: \.self) { option in
                    Text("\(option)")
                        .tag(option.id)
                }
            }
            
            PickerRow(
                systemImage: "folder",
                title: "Category",
                selection: $category
            ) {
                ForEach(TransactionCategory.allCases, id: \.self) { option in
                    Text("\(option)")
                        .tag(option.id)
                }
            }
            
            LabeledRow(systemImage: "calendar.badge.plus", title: "Date") {
                DatePicker(selection: $date, displayedComponents: .date) {
                    
                }
                .datePickerStyle(.compact)
            }
        }
    }
    
    private struct PickerRow<PickerOption, PickerOptionsContent>: View where PickerOption : Hashable & CustomStringConvertible, PickerOptionsContent : View {
        let systemImage: String
        let title: String
        @Binding var selection: PickerOption
        @ViewBuilder var pickerOptionsContent: () -> PickerOptionsContent
        
        var body: some View {
            LabeledRow(systemImage: systemImage, title: title) {
                Menu {
                    Picker(selection: $selection) {
                        pickerOptionsContent()
                    } label: {
                        Text(title)
                    }
                } label: {
                    Label {
                        Text(selection.description)
                    } icon: {
                        Image(systemName: "chevron.up.chevron.down")
                    }
                }
                .labelStyle(.menuLabel)
                .foregroundStyle(.secondary)
            }
        }
    }
    
    private struct LabeledRow<Content>: View where Content : View {
        let systemImage: String
        let title: String
        @ViewBuilder let content: () -> Content
        
        var body: some View {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(.blue)
                    .imageScale(.large)
                
                Text(title)
                
                Spacer()
                
                content()
            }
            .sheetDetailRow()
        }
    }
}

#Preview("Content View") {
    ContentView()
}

#Preview("Sheet Content View") {
    SheetContentView(isFullScreen: .constant(true))
}

#Preview("Sheet Details") {
    SheetDetailsView()
}
