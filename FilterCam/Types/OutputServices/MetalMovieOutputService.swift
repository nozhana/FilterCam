//
//  MetalMovieOutputService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import Combine
import FilterCamInterfaces
import FilterCamShared
import Foundation
import GPUImage

final class MetalMovieOutputService: MovieOutputService {
    @Published var captureActivity: CaptureActivity = .idle
    
    var captureActivityPublisher: AnyPublisher<CaptureActivity, Never> {
        $captureActivity.eraseToAnyPublisher()
    }
    
    private var movieOutput = MetalMovieCaptureOutput()
    
    var output: some MetalCaptureOutput { movieOutput }
    
    private var continuation: VideoContinuation?
    private var outputURL: URL?
    
    private var timer: Timer?
    
    func recordVideo(with features: VideoFeatures) async throws -> Video {
        let movieID = UUID()
        outputURL = MediaStore.shared.moviesDirectory.appendingPathComponent(movieID.uuidString, conformingTo: .quickTimeMovie)
        movieOutput = try .init(url: outputURL!)
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            movieOutput.output.startRecording()
            timer = .scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                let duration = self.captureActivity.duration + 0.1
                self.captureActivity = .video(duration: duration)
            }
            timer?.fire()
        }
    }
    
    func stopRecording() {
        movieOutput.output.finishRecording { [weak self] in
            guard let self, let outputURL else {
                self?.continuation?.resume(throwing: VideoRecordingError.noVideoData)
                self?.continuation = nil
                self?.timer?.invalidate()
                self?.timer = nil
                self?.captureActivity = .idle
                return
            }
            let video = Video(fileURL: outputURL)
            continuation?.resume(returning: video)
            continuation = nil
            self.outputURL = nil
            self.timer?.invalidate()
            self.timer = nil
            captureActivity = .idle
        }
    }
}

extension MovieOutputService where Self == MetalMovieOutputService {
    static func metal() -> MetalMovieOutputService {
        .init()
    }
}
