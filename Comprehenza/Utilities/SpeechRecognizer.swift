import Foundation
import Speech
import AVFoundation

// MARK: - Speech Recognizer Utility
class SpeechRecognizer: ObservableObject {
    @Published var spokenWords: [String] = []
    @Published var isListening: Bool = false
    @Published var transcript: String = ""

    private var audioEngine        = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask:    SFSpeechRecognitionTask?
    private let speechRecognizer   = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func startRecording() {
        spokenWords = []
        transcript  = ""

        guard let recognizer = speechRecognizer, recognizer.isAvailable else { return }

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest else { return }
        req.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format    = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            req.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()
        isListening = true

        recognitionTask = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self = self, let result = result else { return }
            DispatchQueue.main.async {
                self.transcript  = result.bestTranscription.formattedString
                self.spokenWords = self.transcript
                    .lowercased()
                    .components(separatedBy: .whitespaces)
                    .map { $0.trimmingCharacters(in: .punctuationCharacters) }
                    .filter { !$0.isEmpty }
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
