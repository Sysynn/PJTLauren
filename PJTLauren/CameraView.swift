import SwiftUI
import AVFoundation
import Vision

struct CameraView: UIViewControllerRepresentable {
    @Binding var recognizedText: String

    func makeUIViewController(context: Context) -> some UIViewController {
        let cameraViewController = CameraViewController()
        cameraViewController.delegate = context.coordinator
        return cameraViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func didRecognizeText(_ text: String) {
            DispatchQueue.main.async {
                self.parent.recognizedText = text
            }
        }
    }
}
