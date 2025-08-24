//
//  DefaultMovieOutputService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import AVFoundation
import Combine
import UIKit

final class DefaultMovieOutputService: MovieOutputService {
    private let movieOutput = AVCaptureMovieFileOutput()
    
    var output: some DefaultCaptureOutput { DefaultMovieCaptureOutput(output: movieOutput) }
    @Published private(set) var captureActivity: CaptureActivity = .idle
    
    var captureActivityPublisher: AnyPublisher<CaptureActivity, Never> {
        $captureActivity.eraseToAnyPublisher()
    }
    
    func recordVideo(with features: VideoFeatures) async throws -> Video {
        try await withCheckedThrowingContinuation { continuation in
            let movieID = UUID()
            let fileURL = MediaStore.shared.moviesDirectory.appendingPathComponent(movieID.uuidString, conformingTo: .mpeg4Movie)
            let delegate = FileOutputRecordingDelegate(continuation: continuation, movieID: movieID)
            monitorProgress(of: delegate)
            movieOutput.startRecording(to: fileURL, recordingDelegate: delegate)
        }
    }
    
    func stopRecording() {
        movieOutput.stopRecording()
    }
    
    private func monitorProgress(of delegate: FileOutputRecordingDelegate, isolation: (any Actor)? = #isolation) {
        Task {
            for await activity in delegate.activityStream {
                captureActivity = activity
            }
        }
    }
}

extension MovieOutputService where Self == DefaultMovieOutputService {
    static func `default`() -> DefaultMovieOutputService {
        .init()
    }
}

typealias VideoContinuation = CheckedContinuation<Video, Error>

private final class FileOutputRecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    private let continuation: VideoContinuation
    private let movieID: UUID
    
    private var cancellables = Set<AnyCancellable>()
    
    private var videoData: Data?
    
    private var interval = 0.0
    
    let activityStream: ActivityStream
    private let activityContinuation: ActivityStream.Continuation
    
    init(continuation: VideoContinuation, movieID: UUID) {
        self.continuation = continuation
        self.movieID = movieID
        (activityStream, activityContinuation) = AsyncStream.makeStream()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        logger.debug("Started recording to \(fileURL.absoluteString)")
        activityContinuation.yield(.video(duration: .zero))
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                interval += 0.1
                activityContinuation.yield(.video(duration: interval))
            }
            .store(in: &cancellables)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        defer { cancellables.removeAll() }
        activityContinuation.yield(.idle)
        interval = 0.0
        let thumbnailData = thumbnailData(forVideoAt: outputFileURL)
        let video = Video(id: movieID, fileURL: outputFileURL, thumbnailData: thumbnailData)
        continuation.resume(returning: video)
    }
    
    private func thumbnailData(forVideoAt url: URL) -> Data? {
        do {
            let asset = AVURLAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage).preparingThumbnail(of: .init(width: 100, height: 100))
            return thumbnail?.pngData()
        } catch {
            logger.error("Failed to generate thumbnail data for video at \(url.absoluteString)")
            return nil
        }
    }
}
