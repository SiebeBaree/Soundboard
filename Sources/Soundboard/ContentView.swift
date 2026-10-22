import SwiftUI

/// The whole app window: title bar, menu row, toolbar, pad grid and status bar.
struct ContentView: View {
    @Environment(Board.self) private var board
    @State private var importing = false
    @State private var dropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            TitleBar()
            MenuRow(importing: $importing)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Button("Random!") { board.playRandom() }
                        .buttonStyle(.win95(isDefault: true))
                        .keyboardShortcut(.space, modifiers: [])
                        .disabled(board.sounds.isEmpty)
                    Button("Add Sound...") { importing = true }
                        .buttonStyle(.win95())
                    Button("Stop") { board.stop() }
                        .buttonStyle(.win95())
                        .keyboardShortcut(.escape, modifiers: [])
                        .disabled(board.nowPlaying == nil)
                }
                PadGrid(importing: $importing, dropTargeted: dropTargeted)
                StatusBar()
            }
            .padding(8)
        }
        .padding(3)
        .background(Color.w95Face)
        .bevel(.raised)
        .font(.w95)
        .foregroundStyle(.black)
        .frame(minWidth: 420, minHeight: 300)
        .dropDestination(for: URL.self) { urls, _ in
            board.add(urls)
            return true
        } isTargeted: { dropTargeted = $0 }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result { board.add(urls) }
        }
    }
}

/// Navy gradient bar that drags the window, with minimize, zoom and close boxes.
private struct TitleBar: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 10))
            Text("Soundboard.exe").bold()
            Spacer()
            box("minus") { NSApp.keyWindow?.miniaturize(nil) }
            box("square") { NSApp.keyWindow?.zoom(nil) }
            box("xmark") { NSApp.terminate(nil) }
                .padding(.leading, 2)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
        .frame(height: 20)
        .background(LinearGradient(colors: [.w95Navy, .w95Blue], startPoint: .leading, endPoint: .trailing))
        .gesture(WindowDragGesture())
    }

    private func box(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 7, weight: .black))
                .frame(width: 16, height: 14)
        }
        .buttonStyle(.win95(compact: true))
    }
}

private struct MenuRow: View {
    @Environment(Board.self) private var board
    @Binding var importing: Bool

    var body: some View {
        HStack(spacing: 0) {
            Menu {
                Button("Add Sound...") { importing = true }
                Button("Open Sound Folder") { board.openFolder() }
                Divider()
                Button("Exit") { NSApp.terminate(nil) }
            } label: { title("File") }
            Menu {
                Button("Random") { board.playRandom() }
                Button("Stop") { board.stop() }
            } label: { title("Sounds") }
            Menu {
                Button("Agent Instructions") { board.openReadme() }
            } label: { title("Help") }
            Spacer()
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .padding(.vertical, 2)
    }

    /// Menu title with the first letter underlined, like an Alt shortcut.
    private func title(_ name: String) -> some View {
        Text("\(Text(name.prefix(1)).underline())\(String(name.dropFirst()))")
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .fixedSize()
    }
}

private struct PadGrid: View {
    @Environment(Board.self) private var board
    @Binding var importing: Bool
    var dropTargeted: Bool

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 6)], spacing: 6) {
                ForEach(board.sounds) { sound in
                    Button { board.play(sound) } label: { pad(sound.name) }
                        .buttonStyle(.win95(isDown: board.nowPlaying == sound))
                        .contextMenu {
                            Button("Show in Finder") { board.reveal(sound) }
                            Button("Move to Trash") { board.trash(sound) }
                        }
                }
                Button { importing = true } label: { pad("+") }
                    .buttonStyle(.win95())
            }
            .padding(8)
        }
        .background(dropTargeted ? Color.w95Light : .white)
        .bevel(.field)
    }

    private func pad(_ label: String) -> some View {
        Text(label)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 26)
    }
}

private struct StatusBar: View {
    @Environment(Board.self) private var board

    var body: some View {
        HStack(spacing: 4) {
            field(board.nowPlaying.map { "Playing: \($0.url.lastPathComponent)" } ?? "Ready")
            field(board.sounds.count == 1 ? "1 sound" : "\(board.sounds.count) sounds")
        }
    }

    private func field(_ text: String) -> some View {
        Text(text)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .bevel(.field)
    }
}
