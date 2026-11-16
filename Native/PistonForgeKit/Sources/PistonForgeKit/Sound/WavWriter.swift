import Foundation

/// Writes mono 16-bit PCM WAV files, for listening to the engine sound outside the app.
public enum WavWriter {
    public static func write(samples: [Float], sampleRate: Int, to url: URL) throws {
        var data = Data(capacity: 44 + samples.count * 2)
        func append32(_ value: UInt32) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        func append16(_ value: UInt16) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        let payload = UInt32(samples.count * 2)
        data.append(contentsOf: Array("RIFF".utf8))
        append32(36 + payload)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        append32(16)
        append16(1) // PCM
        append16(1) // mono
        append32(UInt32(sampleRate))
        append32(UInt32(sampleRate * 2))
        append16(2)
        append16(16)
        data.append(contentsOf: Array("data".utf8))
        append32(payload)
        for sample in samples {
            let clipped = sample.isFinite ? min(max(sample, -1), 1) : 0
            append16(UInt16(bitPattern: Int16((clipped * 32_767).rounded())))
        }
        try data.write(to: url, options: .atomic)
    }
}
