import SwiftUI
import UIKit

/// A thin SwiftUI wrapper over `UIImagePickerController` in camera mode — the one avatar source
/// `PhotosPicker` can't provide, since that only reads the existing library. It hands back JPEG
/// `Data` (which is `Sendable`), mirroring how the `PhotosPicker` path already yields `Data`, so
/// nothing non-`Sendable` crosses back into the caller.
///
/// Like the position `Menu` and `PhotosPicker` itself, this is a transient *system* control, not
/// app navigation — so it lives in the View and is dismissed by SwiftUI, rather than being routed
/// by a Coordinator. The presenting View gates it on `UIImagePickerController.isSourceTypeAvailable(.camera)`
/// (the Simulator has no camera).
struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    /// Called with the captured photo as JPEG data. Not called at all if the parent backs out.
    let onCapture: (Data) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .rear
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onFinish: dismiss)
    }

    /// `UIImagePickerController`'s delegate methods are nonisolated protocol requirements, so the
    /// Coordinator can't be `@MainActor`-isolated without a conformance error. UIKit invokes them
    /// on the main thread at runtime, so we hop back onto the main actor explicitly to touch the
    /// main-actor closures.
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (Data) -> Void
        private let onFinish: DismissAction

        init(onCapture: @escaping (Data) -> Void, onFinish: DismissAction) {
            self.onCapture = onCapture
            self.onFinish = onFinish
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // Encode to `Data` here, off the closures, so only a `Sendable` value is handed back.
            let data = (info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.9)
            MainActor.assumeIsolated {
                if let data { onCapture(data) }
                onFinish()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            MainActor.assumeIsolated {
                onFinish()
            }
        }
    }
}
