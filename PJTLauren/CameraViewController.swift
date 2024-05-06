import UIKit
import AVFoundation
import Vision

protocol CameraViewControllerDelegate: AnyObject {
    func didRecognizeText(_ text: String)
}

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var textOverlayView: UILabel = UILabel()  // 텍스트 오버레이 뷰 추가
    var lastUpdateTime: Date = Date(timeIntervalSince1970: 0)  // 마지막 업데이트 시간 초기화
    var videoCaptureDevice: AVCaptureDevice?  // 비디오 캡쳐 디바이스

    weak var delegate: CameraViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        startCamera()
        setupTextOverlay()  // 텍스트 오버레이 설정
        addPinchGesture()  // 핀치 제스처 추가
    }

    func setupTextOverlay() {
        textOverlayView.backgroundColor = UIColor.yellow.withAlphaComponent(0.5)
        textOverlayView.textAlignment = .center
        textOverlayView.numberOfLines = 0
        textOverlayView.font = UIFont.systemFont(ofSize: UIFont.labelFontSize * 3)
        view.addSubview(textOverlayView)
        textOverlayView.translatesAutoresizingMaskIntoConstraints = false
        textOverlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        textOverlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        textOverlayView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
    }

    func startCamera() {
        captureSession = AVCaptureSession()
        videoCaptureDevice = AVCaptureDevice.default(for: .video)
        guard let captureSession = captureSession, let videoCaptureDevice = videoCaptureDevice else { return }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            failed()
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let videoOutput = AVCaptureVideoDataOutput()
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            videoOutput.alwaysDiscardsLateVideoFrames = true
        } else {
            failed()
            return
        }

        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.frame = view.layer.bounds
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(videoPreviewLayer!, at: 0)

        captureSession.startRunning()
    }

    func addPinchGesture() {
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinchRecognizer)
    }

    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let device = videoCaptureDevice else { return }
        if recognizer.state == .changed {
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let pinchVelocityDividerFactor: CGFloat = 5.0

            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }

                let desiredZoomFactor = device.videoZoomFactor + atan2(recognizer.velocity, pinchVelocityDividerFactor)
                device.videoZoomFactor = max(1.0, min(desiredZoomFactor, maxZoomFactor))
            } catch {
                print("Error accessing zoom factor: \(error)")
            }
        }
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                return
            }

            let texts = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: ", ")

            let numbersInText = texts.split(separator: ", ").map(String.init).filter { $0.range(of: "^[0-9]+$", options: .regularExpression) != nil }
            let koreanNumbers = numbersInText.map { number -> String in
                numberToKorean(Int(number) ?? 0)
            }.joined(separator: ", ")

            let currentTime = Date()
            if currentTime.timeIntervalSince(self?.lastUpdateTime ?? Date(timeIntervalSince1970: 0)) >= 1 {
                DispatchQueue.main.async {
                    self?.textOverlayView.text = koreanNumbers
                    self?.lastUpdateTime = currentTime
                }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}
