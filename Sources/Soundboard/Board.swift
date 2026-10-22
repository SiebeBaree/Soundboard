import AVFoundation
import AppKit
import Observation
import UniformTypeIdentifiers

/// One audio file in the sound folder. The file name is the label: `sad_trombone.wav` shows as "Sad Trombone".
/// Only first letters are raised, so `FBI_open_up.mp3` keeps its "FBI".
struct Sound: Identifiable, Hashable {
    let url: URL
    var id: URL { url }
    var name: String {
        url.deletingPathExtension().lastPathComponent
            .split(separator: /[_\-\s]+/)
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

/// The sound library and player. Every audio file in `~/Soundboard` is a pad.
/// The folder is watched, so files copied in by agents or Finder show up live.
@MainActor @Observable
final class Board: NSObject, AVAudioPlayerDelegate {
    static let folder = URL.homeDirectory.appending(path: "Soundboard", directoryHint: .isDirectory)
    static let readme = folder.appending(path: "README.md")

    private(set) var sounds: [Sound] = []
    private(set) var nowPlaying: Sound?

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var watcher: DispatchSourceFileSystemObject?

    override init() {
        super.init()
        prepareFolder()
        reload()
        watch()
    }

    func play(_ sound: Sound) {
        player?.stop()
        guard let player = try? AVAudioPlayer(contentsOf: sound.url) else {
            nowPlaying = nil
            return
        }
        player.delegate = self
        player.play()
        self.player = player
        nowPlaying = sound
    }

    /// Plays any sound except the one played last, so two presses never repeat.
    func playRandom() {
        let pool = sounds.count > 1 ? sounds.filter { $0.url != player?.url } : sounds
        if let sound = pool.randomElement() { play(sound) }
    }

    func stop() {
        player?.stop()
        nowPlaying = nil
    }

    /// Copies audio files into the folder. Non-audio files are skipped, name clashes get a number.
    func add(_ urls: [URL]) {
        for url in urls where Self.isAudio(url) {
            try? FileManager.default.copyItem(at: url, to: destination(for: url))
        }
        reload()
    }

    func trash(_ sound: Sound) {
        if nowPlaying == sound { stop() }
        try? FileManager.default.trashItem(at: sound.url, resultingItemURL: nil)
        reload()
    }

    func reveal(_ sound: Sound) {
        NSWorkspace.shared.activateFileViewerSelecting([sound.url])
    }

    func openFolder() {
        NSWorkspace.shared.open(Self.folder)
    }

    func openReadme() {
        NSWorkspace.shared.open(Self.readme)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let finished = ObjectIdentifier(player)
        Task { @MainActor in
            if let current = self.player, ObjectIdentifier(current) == finished { self.nowPlaying = nil }
        }
    }

    // MARK: Folder

    private static func isAudio(_ url: URL) -> Bool {
        UTType(filenameExtension: url.pathExtension)?.conforms(to: .audio) == true
    }

    private func reload() {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: Self.folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
        )) ?? []
        sounds = urls.filter(Self.isAudio)
            .map { Sound(url: $0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Creates the folder on first launch and seeds it with the classic macOS alert sounds.
    private func prepareFolder() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: Self.folder.path) {
            try? fm.createDirectory(at: Self.folder, withIntermediateDirectories: true)
            let system = URL(filePath: "/System/Library/Sounds")
            for url in (try? fm.contentsOfDirectory(at: system, includingPropertiesForKeys: nil)) ?? [] {
                try? fm.copyItem(at: url, to: Self.folder.appending(path: url.lastPathComponent))
            }
        }
        if !fm.fileExists(atPath: Self.readme.path) {
            try? agentReadme.write(to: Self.readme, atomically: true, encoding: .utf8)
        }
    }

    /// Reloads whenever a file is added, removed or renamed in the folder.
    private func watch() {
        let fd = open(Self.folder.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.reload() }
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        watcher = source
    }

    private func destination(for url: URL) -> URL {
        let base = url.deletingPathExtension().lastPathComponent
        var candidate = Self.folder.appending(path: url.lastPathComponent)
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = Self.folder.appending(path: "\(base) \(n).\(url.pathExtension)")
            n += 1
        }
        return candidate
    }
}

private let agentReadme = """
# Soundboard

Every audio file in this folder is a pad in the Soundboard app.

To add a sound, copy an audio file (wav, mp3, m4a, aiff, caf) into this folder.
The app picks it up right away, no restart needed.

The file name becomes the pad label: `sad_trombone.wav` shows as "Sad Trombone".
Delete a file to remove its pad.

"""
