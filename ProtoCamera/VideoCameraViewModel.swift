//
//  VideoCameraViewModel.swift
//  ProtoCamera
//
//  Created by Win Raguini on 12/11/16.
//  Copyright © 2016 Win Inc. All rights reserved.
//

import UIKit
import PureLayout
import Bond

protocol CameraViewModelDelegate: class {
    func configureAllViews()
    func didStartRecording()
    func didStopRecording()
    func dismissView()
    func toggleCamera()
}

protocol User {
    var name: String { get }
}


struct JackUser: User {
    var name: String {
        return "Jack B. Nymbal"
    }
}


class CameraViewModel {

    var cameraDisplayed = Observable<Bool>(true)

    var maxVideoLength: Float = 60.0

    weak var delegate: CameraViewModelDelegate?

    var videoLength = Observable<Float> (0.0)

    var videoLengthText = Observable<String> ("")

    var videoLengthPercent = Observable<Float> (0.0)

    var videoSegments = Observable<[VideoSegment]> ([])

    var videoIsRecording = Observable<Bool>(false)

    var lastVideoSegmentLength: Float = 0.0

    var videoSegmentsRecorded = Observable<Bool>(false)

    var videoLengthMaxReached = Observable<Bool>(false)

    var question: String {
        return "How does this video thing work?"
    }

    var attributedText: NSAttributedString {
        return "\(user.name) asked: \n \(question)".withTextColor(.white)
    }

    var user: User {
        return JackUser()
    }

    func addSegmentURL(segmentUrl: URL)  {
        let videoLengthDifference = videoLength.value - lastVideoSegmentLength
        let videoSegment  = VideoSegment(videoURL: segmentUrl, videoLength: videoLengthDifference)
        lastVideoSegmentLength = videoLength.value
        videoSegments.value.append(videoSegment)
    }

    func recordButtonPressed() {
        if (!self.videoLengthMaxReached.value) {
            print("Start recording")
            delegate?.didStartRecording()
        }
    }

    func recordButtonDepressed() {
        print("Stop recording")
        delegate?.didStopRecording()
    }

    func closeButtonPressed() {
        print ("Close button pressed")
        delegate?.dismissView()
    }

    func toggleCameraButtonPressed() {
        delegate?.toggleCamera()
    }

    func setCurrentFilePath(filePath: URL) {

    }

    func deleteLastSegment() {
        guard let lastSegment = self.videoSegments.value.popLast() else {return}
        videoLength.value -= lastSegment.videoLength
        guard let lastVideoSegment = self.videoSegments.value.last, self.videoSegments.value.count > 0 else {
            lastVideoSegmentLength = 0.0
            return
        }
        lastVideoSegmentLength = lastVideoSegment.videoLength
    }

    func timerDisplay(seconds: Float) -> String {
        return String(format: "00:%02d", Int(seconds))
    }

    convenience init(maxVideoLength: Float) {
        self.init()
        self.maxVideoLength = maxVideoLength
    }

    init() {
        videoLength
            .map({[unowned self] in
                "\(self.timerDisplay(seconds: $0))"
            })
            .bind(to: videoLengthText)

        videoLength
            .map({[unowned self] in
                Float($0)/self.maxVideoLength
            })
            .bind(to: videoLengthPercent)

        videoSegments
            .map({$0.count > 0})
            .bind(to: videoSegmentsRecorded)

        videoLength
            .map({[unowned self] in
                $0 >= self.maxVideoLength
            })
            .bind(to: videoLengthMaxReached)
    }
}
