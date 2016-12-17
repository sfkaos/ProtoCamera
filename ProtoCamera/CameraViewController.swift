//
//  CameraViewController.swift
//  ProtoCamera
//
//  Created by Win Raguini on 11/25/16.
//  Copyright © 2016 Win Inc. All rights reserved.
//

import UIKit
import AVFoundation
import PureLayout
import SwiftyAttributes
import ChameleonFramework
import Bond
import SCLAlertView

struct VideoSegment {
    var videoURL: URL
    var videoLength: Float
}

protocol VideoProcessor {
    func mergeVideoSegments(videoSegments: [VideoSegment], completionHandler: ((AVAssetExportSession) -> Void)?)
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    enum CameraPosition {
        case front, rear
        mutating func toggle() {
            switch self {
            case .front:
                self = .rear
            case .rear:
                self = .front
            }
        }
        func devicePosition() -> AVCaptureDevicePosition {
            switch self {
            case .front:
                return AVCaptureDevicePosition.front
            default:
                return AVCaptureDevicePosition.back
            }
        }
    }

    let progressBarHeight: CGFloat = 5.0

    //Timer
    var startTime = TimeInterval()
    var timer = Timer()

    var cameraSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var dataOutput: AVCaptureMovieFileOutput?
    var deviceInput: AVCaptureDeviceInput?

    var delegate:AVCaptureFileOutputRecordingDelegate?

    //Configuring view
    var previewView: UIView!
    var closeButton: UIButton!
    var recordButton: UIButton!
    var toggleCameraButton: UIButton!
    var playButton: UIButton!
    var deleteButton: UIButton!
    var doneButton: UIButton!
    var progressView: UIProgressView!
    var backgroundView: UIView!
    var questionLabel: UILabel!

    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?

    var timerLabel: UILabel!

    var isRecording = false
    var isPreviewing = false
    var currentCameraPosition = CameraPosition.front

    var currentFilePath: URL?    

    var viewModel: CameraViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        view.backgroundColor = UIColor.black
        configureAllViews()

        closeButton.bnd_tap.observe {[weak self] _ in
            guard let weakSelf = self else {return}
            weakSelf.viewModel?.closeButtonPressed()
        }.disposeIn(bnd_bag)

        deleteButton.bnd_tap.observeNext {[weak self] _ in
            guard let weakSelf = self else {return}
            weakSelf.showDeleteAlert()
        }.disposeIn(bnd_bag)

        recordButton.bnd_controlEvents(.touchDown).observeNext {[weak self] _ in
            guard let weakSelf = self else {return}
            weakSelf.recordButtonPressed()
        }.disposeIn(bnd_bag)

        recordButton.bnd_controlEvents([.touchUpOutside , .touchUpInside]).observeNext {[weak self] _ in
            guard let weakSelf = self else {return}
            weakSelf.recordButtonDepressed()
        }.disposeIn(bnd_bag)

        toggleCameraButton.bnd_controlEvents([.touchDown]).observeNext {[weak self] _ in
            guard let weakSelf = self else {return}
            weakSelf.toggleCameraButtonPressed()
        }.disposeIn(bnd_bag)

        playButton.bnd_controlEvents([.touchDown]).observeNext {[weak self] _ in
            guard let weakSelf = self else {return}
            weakSelf.playButtonPressed()
        }.disposeIn(bnd_bag)

        doneButton.bnd_controlEvents([.touchDown]).observeNext {[weak self] _ in
            guard let weakSelf = self else {return}
            weakSelf.doneButtonPressed()
        }.disposeIn(bnd_bag)

        bindViewModel()
    }

    func showDeleteAlert() {
        let alertView = SCLAlertView()
        alertView.addButton("Yes, delete it.") { [weak self] _ in
            guard let weakSelf = self else {return}
            weakSelf.viewModel?.deleteLastSegment()
        }

        alertView.showTitle(
            "Delete last segment?",
            subTitle: "This cannot be undone.",
            duration: 0.0,
            completeText: "Cancel",
            style: .warning, 
            colorStyle: 0xA429FF,
            colorTextButton: 0xFFFFFF
        )

    }

    func bindViewModel() {
        viewModel?.videoLengthText.bind(to: timerLabel.bnd_text)
        viewModel?.videoLengthPercent.bind(to: progressView.bnd_progress)
        viewModel?.videoIsRecording.bind(to: closeButton.bnd_isHidden)
        viewModel?.videoIsRecording.bind(to: deleteButton.bnd_isHidden)
        viewModel?.videoIsRecording.bind(to: doneButton.bnd_isHidden)
        viewModel?.videoIsRecording.bind(to: playButton.bnd_isHidden)
        viewModel?.videoSegmentsRecorded.map({ !$0 }).bind(to: playButton.bnd_isHidden)
        viewModel?.videoSegmentsRecorded.map({ !$0 }).bind(to: deleteButton.bnd_isHidden)
        viewModel?.videoSegmentsRecorded.map({ !$0 }).bind(to: doneButton.bnd_isHidden)
        viewModel?.cameraDisplayed.map({!$0}).bind(to: closeButton.bnd_isHidden)
    }


    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer!.frame = self.previewView.bounds

        previewView.addSubview(backgroundView)
        backgroundView.autoPinEdgesToSuperviewEdges()
        backgroundView.backgroundColor = GradientColor(.topToBottom, frame: backgroundView.frame, colors: [.black, .clear, .clear, .clear, .clear, .clear, .clear])

        previewView.addSubview(closeButton)
        closeButton.autoPinEdge(.top, to: .top, of: previewView, withOffset: 20.0)
        closeButton.autoPinEdge(toSuperviewEdge: .left, withInset: 20.0)

        previewView.addSubview(questionLabel)
        questionLabel.numberOfLines = 0
        questionLabel.autoPinEdge(.left, to: .left, of: previewView, withOffset: 20.0)
        questionLabel.autoPinEdge(.top, to: .bottom, of: closeButton, withOffset: -10.0)
        questionLabel.autoPinEdge(.right, to: .right, of: previewView, withOffset: -20.0)
        questionLabel.attributedText = viewModel?.attributedText
        questionLabel.autoSetDimension(.height, toSize: 100)

        previewView.addSubview(toggleCameraButton)
        toggleCameraButton.autoPinEdge(.top, to: .top, of: previewView, withOffset: 20.0)
        toggleCameraButton.autoPinEdge(.right, to: .right, of: previewView, withOffset: -20.0)

        previewView.addSubview(playButton)
        playButton.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
        playButton.autoPinEdge(.bottom, to: .bottom, of: previewView, withOffset: -20.0)

        previewView.addSubview(recordButton)
        recordButton.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)
        recordButton.autoPinEdge(.bottom, to: .top, of: playButton, withOffset: -20.0)

        previewView.addSubview(deleteButton)
        deleteButton.autoPinEdge(.left, to: .left, of: previewView, withOffset: 20.0)
        deleteButton.autoPinEdge(.bottom, to: .bottom, of: previewView, withOffset: -20.0)

        previewView.addSubview(doneButton)
        doneButton.autoPinEdge(.right, to: .right, of: previewView, withOffset: -20.0)
        doneButton.autoPinEdge(.bottom, to: .bottom, of: previewView, withOffset: -20.0)

        previewView.addSubview(timerLabel)
        timerLabel.autoPinEdge(.bottom, to: .top, of: recordButton, withOffset: -20.0)
        timerLabel.autoAlignAxis(toSuperviewAxis: ALAxis.vertical)

        previewView.addSubview(progressView)
        progressView.autoPinEdge(.top, to: .top, of: previewView, withOffset: 0.0)
        progressView.autoPinEdge(.left, to: .left, of: previewView, withOffset: 8.0)
        progressView.autoPinEdge(.right, to: .right, of: previewView, withOffset: -8.0)
        progressView.layer.cornerRadius = progressBarHeight/2
        progressView.layer.masksToBounds = true
        progressView.autoSetDimension(ALDimension.height, toSize: progressBarHeight)
    }

    func configureAllViews()  {
        configureView()
        cameraSession = AVCaptureSession()
        cameraSession!.sessionPreset = AVCaptureSessionPresetMedium
        configureCamera()
        configureAudio()
        cameraSession?.startRunning()
        configurePreview()
    }

    func configureView() -> Void {
        previewView = UIView(frame: CGRect.zero)
        view.addSubview(previewView)
        previewView.autoPinEdgesToSuperviewEdges()
        let tapViewRecognizer = UITapGestureRecognizer(target: self, action: #selector(CameraViewController.didTapView(_:)))
        previewView.addGestureRecognizer(tapViewRecognizer)

        backgroundView = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize.zero))

        questionLabel = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize.zero))
        questionLabel.numberOfLines = 0

        closeButton = UIButton(type: .custom)
        closeButton.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 10.0, height: 10.0))
        let closeBtnImage = UIImage.init(named: "closeBtn")?.withRenderingMode(.alwaysTemplate)
        closeButton.setBackgroundImage(closeBtnImage, for: .normal)
        closeButton.tintColor = UIColor.white

        recordButton = UIButton(type: .custom)
        recordButton.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 40.0, height: 40.0))
        recordButton.setTitle("Record", for: .normal)

        toggleCameraButton = UIButton(type: .custom)
        toggleCameraButton.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 16.0, height: 16.0))
        let toggleCameraImage = UIImage.init(named: "redo")?.withRenderingMode(.alwaysTemplate)
        toggleCameraButton.setBackgroundImage(toggleCameraImage, for: .normal)
        toggleCameraButton.tintColor = UIColor.white

        playButton = UIButton(type: .custom)
        playButton.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 40.0, height: 40.0))
        playButton.setTitle("Preview", for: .normal)

        deleteButton = UIButton(type: .custom)
        deleteButton.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 40.0, height: 40.0))
        deleteButton.setTitle("Delete", for: .normal)

        doneButton = UIButton(type: .custom)
        doneButton.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 40.0, height: 40.0))
        doneButton.setTitle("Done", for: .normal)

        timerLabel = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 40.0, height: 20.0)))
        timerLabel.backgroundColor = UIColor.lightGray
        timerLabel.attributedText = "01:00".withTextColor(.white)

        progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.bar)
        progressView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.width, height: 10.0))
        progressView.progressTintColor = UIColor.white
        progressView.progress = 1.0
    }

    func configureCamera() -> Void {
        do {
            cameraSession?.beginConfiguration()

            let captureDevice = getDevice()

            if deviceInput != nil {
                cameraSession?.removeInput(deviceInput)
            }

            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            if (cameraSession?.canAddInput(deviceInput) == true) {
                cameraSession?.addInput(deviceInput)
            }

            if dataOutput != nil {
                cameraSession?.removeOutput(dataOutput)
            }

            dataOutput = AVCaptureMovieFileOutput()
            if (cameraSession?.canAddOutput(dataOutput) == true) {
                cameraSession?.addOutput(dataOutput)
            }

            cameraSession?.commitConfiguration()
        }
        catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
    }

    func configureAudio() -> Void {
        do {
            cameraSession?.beginConfiguration()

            let captureDeviceAudio = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            let audioInput = try AVCaptureDeviceInput(device: captureDeviceAudio)
            if (cameraSession?.canAddInput(audioInput) == true) {
                cameraSession?.addInput(audioInput)
            }
            cameraSession?.commitConfiguration()
        }
        catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
    }

    func configurePreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
        previewView.layer.addSublayer(previewLayer!)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension CameraViewController: VideoProcessor {
    func mergeVideoSegments(videoSegments: [VideoSegment], completionHandler: ((AVAssetExportSession) -> Void)?) {
        let composition = AVMutableComposition()
        let trackVideo:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let trackAudio:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())

        var insertTime = kCMTimeZero

        if videoSegments.count > 0 {
            for videoSegment in videoSegments {
                let moviePathUrl = videoSegment.videoURL
                let sourceAsset = AVURLAsset(url: moviePathUrl, options: nil)
                let tracks = sourceAsset.tracks(withMediaType: AVMediaTypeVideo)
                let audios = sourceAsset.tracks(withMediaType: AVMediaTypeAudio)
                if tracks.count > 0{
                    do {
                        let assetTrack:AVAssetTrack = tracks[0] as AVAssetTrack
                        try trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), of: assetTrack, at: insertTime)
                        let assetTrackAudio:AVAssetTrack = audios[0] as AVAssetTrack
                        try trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), of: assetTrackAudio, at: insertTime)
                        trackVideo.preferredTransform = assetTrack.preferredTransform
                        insertTime = CMTimeAdd(insertTime, sourceAsset.duration)

                    } catch let error as NSError {
                        NSLog("There was an error: \(error), \(error.localizedDescription)")
                    }

                }
            }

            let completeMovieUrl = tempFileName()
            print("\(completeMovieUrl)")
            if let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
                exporter.outputURL = completeMovieUrl
                exporter.outputFileType = AVFileTypeQuickTimeMovie
                exporter.exportAsynchronously(completionHandler: {
                    switch exporter.status{
                    case .failed:
                        print("failed \(exporter.error)")
                    case .cancelled:
                        print("cancelled \(exporter.error)")
                    default:
                        print("complete")
                        DispatchQueue.main.async(execute: {
                            completionHandler?(exporter)
                        })
                    }
                })
            }
        }

    }

    func playerDidFinishPlaying(note: NSNotification){
        self.stopPreview()
    }
}

extension CameraViewController: CameraViewModelDelegate {
    func dismissView() {
        self.dismiss(animated: true, completion: {})
    }

    func toggleCamera() {
        var restartRecording = false
        if (isRecording) {
            didStopRecording()
            restartRecording = true
        }
        currentCameraPosition.toggle()
        configureCamera()
        if (restartRecording) {
            didStartRecording()
        }
    }

    func getDevice() -> AVCaptureDevice {
        return AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: currentCameraPosition.devicePosition())
    }

    func tempFileName() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timeInterval = Date.init().timeIntervalSinceReferenceDate
        return documentsURL.appendingPathComponent("\(floor(timeInterval))-temp.mov")
    }

    func didStartRecording() {
        isRecording = true
        currentFilePath = tempFileName()
        viewModel?.videoIsRecording.value = true
        dataOutput?.startRecording(toOutputFileURL: currentFilePath, recordingDelegate: delegate)
        startTimer()
    }

    func didStopRecording() -> Void {
        dataOutput?.stopRecording()
        viewModel?.videoIsRecording.value = false
        if (isRecording) {
            isRecording = false
            if let currentFilePath = currentFilePath {
                viewModel?.addSegmentURL(segmentUrl: currentFilePath)
            }
            stopTimer()
        }
    }

    func recordButtonPressed() {
        viewModel?.recordButtonPressed()
    }

    func recordButtonDepressed()  {
        viewModel?.recordButtonDepressed()
    }

    func toggleCameraButtonPressed() {
        viewModel?.toggleCameraButtonPressed()
    }

    func playButtonPressed() {
        isPreviewing = true
        mergeVideoSegments(videoSegments: (viewModel?.videoSegments.value)!, completionHandler: {[unowned self] exportSession in
            if let url = exportSession.outputURL {
                self.player = AVPlayer(url: url)
                NotificationCenter.default.addObserver(self, selector:#selector(self.playerDidFinishPlaying(note:)),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem)
                self.playerLayer = AVPlayerLayer(player: self.player!)
                self.playerLayer!.frame = self.view.bounds
                self.playerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill;
                self.previewView.layer.addSublayer(self.playerLayer!)
                self.player!.play()
            }
        })
    }

    func doneButtonPressed() {
        mergeVideoSegments(videoSegments: (viewModel?.videoSegments.value)!, completionHandler: { exportSession in
            if let url = exportSession.outputURL {
                let alertView = SCLAlertView()
                alertView.showTitle(
                    "Completed recording.",
                    subTitle: "Access the video at \(url).",
                    duration: 0.0,
                    completeText: "Okay",
                    style: .info,
                    colorStyle: 0xA429FF,
                    colorTextButton: 0xFFFFFF
                )
            }
        })
    }

    func didTapView(_ sender: UITapGestureRecognizer) {
        if (isPreviewing) {
            self.stopPreview()
        } else {
            self.toggleCamera()
        }
    }

    func stopPreview()  {
        isPreviewing = false
        player?.replaceCurrentItem(with: nil)
        playerLayer!.removeFromSuperlayer()
    }

    func startTimer() {
        if !timer.isValid {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(CameraViewController.updateTimer), userInfo: nil, repeats: true)
            startTime = NSDate.timeIntervalSinceReferenceDate
        }
    }

    func stopTimer() {
        timer.invalidate()
    }

    func updateTimer()  {
        if (!(viewModel?.videoLengthMaxReached.value)!) {
            viewModel?.videoLength.value += 0.1
        } else {
            self.didStopRecording()
        }
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    @objc(captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:) func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        isRecording = false
        guard let _ = NSData(contentsOf: outputFileURL as URL) else {
            print("Output file could not be created.")
            return
        }
    }

    @objc(captureOutput:didStartRecordingToOutputFileAtURL:fromConnections:) func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        isRecording = true
    }
}
