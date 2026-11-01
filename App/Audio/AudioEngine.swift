import AVFoundation
import UIKit

/// Spielt Klänge und Musik mit AVFoundation (Konzept p2-3, „Engine").
///
/// Klänge: ein `AVAudioEngine`, vorbereitete Spieler mit je einem Varispeed für
/// die Tonhöhe, alle Klänge beim Start als Puffer im Speicher. Musik: zwei
/// `AVAudioPlayer` mit Überblendung, weil sie gestreamt und nahtlos geschleift
/// wird. Fehlt Ton (Simulator ohne Ausgabe, Unterbrechung), bleibt das Spiel
/// unberührt: Jede Methode scheitert still und meldet es nur über `play`.
@MainActor
final class AudioEngine: SoundOutput {
    private let engine = AVAudioEngine()
    private let bus = AVAudioMixerNode()
    private var players: [AVAudioPlayerNode] = []
    private var speeds: [AVAudioUnitVarispeed] = []
    /// Bis wann ein Spieler belegt ist. Auf der Hauptschleife geführt statt über
    /// Rückrufe aus dem Audiofaden, die unter Swift 6 erst umständlich zurück müssten.
    private var busyUntil: [Double] = []
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var music: AVAudioPlayer?
    /// Ausblendende Stücke, bis ihre Blende vorbei ist.
    private var fading: [(player: AVAudioPlayer, until: Double)] = []
    private var musicTarget: Float = 0
    private var suspended = false
    private var observers: [NSObjectProtocol] = []

    init(bundle: Bundle = .main) {
        configureSession()
        loadBuffers(from: bundle)
        buildGraph()
        start()
        observe()
    }

    // MARK: Klänge

    func duration(of file: String) -> Double? {
        buffers[file].map { Double($0.frameLength) / $0.format.sampleRate }
    }

    func play(file: String, gain: Float, rate: Float) -> Bool {
        guard !suspended, engine.isRunning, let buffer = buffers[file] else { return false }
        let now = ProcessInfo.processInfo.systemUptime
        guard let index = busyUntil.firstIndex(where: { $0 <= now }) else { return false }
        let player = players[index]
        speeds[index].rate = rate
        player.volume = gain
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
        busyUntil[index] = now + Double(buffer.frameLength) / buffer.format.sampleRate / Double(rate)
        return true
    }

    func setSoundVolume(_ volume: Float) { bus.outputVolume = volume }

    // MARK: Musik

    func playMusic(file: String, loops: Bool, gain: Float, fade: TimeInterval) {
        fadeAway(music, over: fade)
        music = nil
        musicTarget = gain
        guard let url = Bundle.main.url(forResource: file, withExtension: nil),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = loops ? -1 : 0
        player.volume = 0
        player.prepareToPlay()
        music = player
        guard !suspended else { return }
        player.play()
        player.setVolume(audibleMusicGain, fadeDuration: fade)
    }

    func setMusicGain(_ gain: Float, fade: TimeInterval) {
        musicTarget = gain
        music?.setVolume(audibleMusicGain, fadeDuration: fade)
    }

    func stopMusic(fade: TimeInterval) {
        fadeAway(music, over: fade)
        music = nil
    }

    /// Hört jemand eigene Musik, schweigt unsere; die Klänge bleiben (`.ambient`).
    private var audibleMusicGain: Float {
        AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint ? 0 : musicTarget
    }

    private func fadeAway(_ player: AVAudioPlayer?, over fade: TimeInterval) {
        guard let player else { return }
        player.setVolume(0, fadeDuration: fade)
        fading.append((player, ProcessInfo.processInfo.systemUptime + fade))
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(fade))
            self?.stopFaded()
        }
    }

    private func stopFaded() {
        let now = ProcessInfo.processInfo.systemUptime
        for entry in fading where entry.until <= now { entry.player.stop() }
        fading.removeAll { $0.until <= now }
    }

    // MARK: Lebenslauf

    func suspend() {
        guard !suspended else { return }
        suspended = true
        players.forEach { $0.stop() }
        busyUntil = busyUntil.map { _ in 0 }
        music?.pause()
        engine.pause()
    }

    func resume() {
        guard suspended else { return }
        suspended = false
        start()
        guard let music else { return }
        music.play()
        music.setVolume(audibleMusicGain, fadeDuration: AudioStyle.fadeOut)
    }

    private func configureSession() {
        // `.ambient`: Der Stummschalter gilt, und fremde Musik läuft weiter.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func loadBuffers(from bundle: Bundle) {
        for cue in SoundCue.allCases {
            for file in cue.files {
                guard let url = bundle.url(forResource: file, withExtension: nil),
                      let audio = try? AVAudioFile(forReading: url),
                      let buffer = AVAudioPCMBuffer(pcmFormat: audio.processingFormat,
                                                    frameCapacity: AVAudioFrameCount(audio.length)),
                      (try? audio.read(into: buffer)) != nil else { continue }
                buffers[file] = buffer
            }
        }
    }

    private func buildGraph() {
        // Alle Klänge sind Mono mit 44,1 kHz (tools/ton/ton_bauen.py).
        let format = buffers.values.first?.format
            ?? AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
        engine.attach(bus)
        engine.connect(bus, to: engine.mainMixerNode, format: nil)
        for _ in 0..<AudioStyle.voices {
            let player = AVAudioPlayerNode()
            let speed = AVAudioUnitVarispeed()
            engine.attach(player)
            engine.attach(speed)
            engine.connect(player, to: speed, format: format)
            engine.connect(speed, to: bus, format: format)
            players.append(player)
            speeds.append(speed)
            busyUntil.append(0)
        }
    }

    private func start() {
        guard !engine.isRunning else { return }
        engine.prepare()
        try? engine.start()
    }

    private func observe() {
        let center = NotificationCenter.default
        // Anruf, Siri, Wecker: Die Engine steht danach; beim Ende wieder anlaufen.
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil,
                                            queue: .main) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let began = raw == AVAudioSession.InterruptionType.began.rawValue
            MainActor.assumeIsolated {
                if began { self?.suspend() } else { self?.resume() }
            }
        })
        // Kopfhörer ab oder an: Die Engine baut ihre Ausgabe neu und hält dabei an.
        observers.append(center.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine,
                                            queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.start() }
        })
        // Fremde Musik beginnt oder endet: Spielmusik passt sich an.
        observers.append(center.addObserver(forName: AVAudioSession.silenceSecondaryAudioHintNotification,
                                            object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.music?.setVolume(self.audibleMusicGain, fadeDuration: AudioStyle.fadeOut)
            }
        })
    }
}
