import SwiftUI

@MainActor
struct MuthurTerminal: View {
    @State private var viewModel = MuthurViewModel()
    @FocusState private var isInputFocused: Bool

    let muThUrGreen = Color(red: 0.0, green: 0.8, blue: 0.0)

    var body: some View {
        VStack(spacing: 0) {
            headerView
            logView
            inputView
        }
        .onAppear {
            viewModel.bootSequence()
            isInputFocused = true
        }
        .onTapGesture {
            isInputFocused = true
        }
        .onDisappear {
            viewModel.cleanup()
        }
        // Esc interrupts a running process regardless of input focus. A hidden
        // shortcut button is used because the input field is disabled (and thus
        // unfocused) while a command is in flight.
        .background(
            Button("Interrupt") {
                viewModel.interrupt()
            }
            .keyboardShortcut(.escape, modifiers: [])
            .opacity(0)
        )
        // Ctrl-D logs out (terminal-style EOF) when the input line is empty.
        .background(
            Button("Logout") {
                viewModel.requestEOF()
            }
            .keyboardShortcut("d", modifiers: .control)
            .opacity(0)
        )
    }

    private var headerView: some View {
        Text("WEYLAND-YUTANI CORP | MU-TH-UR 6000 | NOSTROMO-2037")
            .font(.system(.subheadline, design: .monospaced))
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(muThUrGreen)
            .foregroundColor(.black)
    }

    private var logView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.consoleLog) { entry in
                        TypewriterText(text: entry.text, color: muThUrGreen, animated: entry.animated)
                            .id(entry.id)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Observe the count (cheap) rather than the whole array (O(n) compare),
            // and skip the per-update animation so high-frequency output stays smooth.
            .onChange(of: viewModel.consoleLog.count) { _, _ in
                if let lastId = viewModel.consoleLog.last?.id {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
        .background(Color.black)
        .overlay(ScanlineOverlay())
    }

    private var inputView: some View {
        @Bindable var viewModel = viewModel
        return HStack {
            Text("[muthur]>>")
                .foregroundColor(viewModel.isProcessing ? muThUrGreen.opacity(0.5) : muThUrGreen)
                .font(.system(.body, design: .monospaced))

            TextField("", text: $viewModel.currentInput)
                .focused($isInputFocused)
                .textFieldStyle(.plain)
                .foregroundColor(muThUrGreen)
                .font(.system(.body, design: .monospaced))
                .onSubmit {
                    Task {
                        await viewModel.processCommand()
                        isInputFocused = true
                    }
                }
                .autocorrectionDisabled()
                .disabled(viewModel.isProcessing)
        }
        .padding()
        .background(Color.black)
        .border(muThUrGreen, width: 1)
        .opacity(viewModel.isProcessing ? 0.7 : 1.0)
    }
}
