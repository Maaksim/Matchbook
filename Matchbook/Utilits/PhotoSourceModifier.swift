//
//  PhotoSourceModifier.swift
//  Matchbook
//

import PhotosUI
import SwiftUI

/// Wires the three transient system presentations behind the avatar picker — the Camera/Gallery
/// chooser, the `PhotosPicker` library sheet, and the `CameraPicker` full-screen cover — so the
/// form body stays declarative. Each is a *system* control, not app navigation, so it belongs on
/// the View rather than a Coordinator (same reasoning as the position `Menu`). The "Take photo"
/// option is hidden when there's no camera (the Simulator).
struct PhotoSourceModifier: ViewModifier {
    @Binding var isChoosingPhotoSource: Bool
    @Binding var isShowingCamera: Bool
    @Binding var isShowingLibrary: Bool
    @Binding var photoItem: PhotosPickerItem?

    let title: LocalizedStringResource
    let isCameraAvailable: Bool
    let onCapture: (Data) -> Void

    func body(content: Content) -> some View {
        content
            .bottomActionSheet(
                isPresented: $isChoosingPhotoSource,
                title: title,
                buttons: sourceButtons
            )
            .photosPicker(isPresented: $isShowingLibrary,
                          selection: $photoItem,
                          matching: .images)
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker(onCapture: onCapture)
                    .ignoresSafeArea()
            }
    }

    /// Camera first (when the device has one), then library, then cancel — the order a native bottom action sheet expects, with cancel visually separated at the foot.
    private var sourceButtons: [ActionSheetButton] {
        var buttons: [ActionSheetButton] = []
        if isCameraAvailable {
            buttons.append(ActionSheetButton(title: "player_take_photo_key") {
                isShowingCamera = true
            })
        }
        buttons.append(ActionSheetButton(title: "player_choose_from_library_key") {
            isShowingLibrary = true
        })

        buttons.append(ActionSheetButton(title: "cancel_key", role: .cancel) {
            isChoosingPhotoSource = false
        })

        return buttons
    }
}

extension View {
    func photoSourceModifier(
        title: LocalizedStringResource,
        isChoosingPhotoSource: Binding<Bool>,
        isShowingCamera: Binding<Bool>,
        isShowingLibrary: Binding<Bool>,
        isCameraAvailable: Bool,
        photoItem: Binding<PhotosPickerItem?>,
        onCapture: @escaping (Data) -> Void
    ) -> some View {
        modifier(PhotoSourceModifier(
            isChoosingPhotoSource: isChoosingPhotoSource,
            isShowingCamera: isShowingCamera,
            isShowingLibrary: isShowingLibrary,
            photoItem: photoItem,
            title: title,
            isCameraAvailable: isCameraAvailable,
            onCapture: onCapture
        ))
    }
}
