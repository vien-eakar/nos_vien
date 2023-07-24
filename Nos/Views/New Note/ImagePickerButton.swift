import AVKit
import SwiftUI

struct ImagePickerButton<Label>: View where Label: View {

    var onCompletion: ((UIImage) -> Void)

    var label: () -> Label

    /// State used to present or hide a confirmation dialog that lets the user select the ImagePicker source.
    @State
    private var showConfirmationDialog = false

    /// State used to present or hide an alert that lets the user go to settings.
    @State
    private var showSettingsAlert = false

    /// Source used by ImagePicker when opening it
    @State
    private var imagePickerSource: UIImagePickerController.SourceType?

    private var showImagePicker: Binding<Bool> {
        Binding {
            imagePickerSource != nil
        } set: { _ in
            imagePickerSource = nil
        }
    }

    private var settingsAlertTitle: String {
        //Localized.ImagePicker.permissionsRequired.text(["title": Localized.ImagePicker.camera.text])
        "something" // todo
    }

    var body: some View {
        Button {
            showConfirmationDialog = true
        } label: {
            label()
        }
        //.confirmationDialog(Localized.select.text, isPresented: $showConfirmationDialog, titleVisibility: .hidden) {
          //  Button(Localized.ImagePicker.takePhoto.text) {
                .confirmationDialog("text1", isPresented: $showConfirmationDialog, titleVisibility: .hidden) {
                    Button("Use the camera") {
                //Analytics.shared.trackDidSelectAction(actionName: "camera")
                // Check permissions

                // simulator
                //guard !UIDevice.isSimulator else {
                //    imagePickerSource = .camera
                //    return
                //}

                // denied
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                guard status != .denied, status != .restricted else {
                    showSettingsAlert = true
                    return
                }

                // allowed
                if status == .authorized {
                    imagePickerSource = .camera
                    return
                }

                // unknown
                AVCaptureDevice.requestAccess(for: .video) { allowed in
                    guard allowed else {
                        showConfirmationDialog = false
                        return
                    }
                    imagePickerSource = .camera
                }
            }
            //Button(Localized.ImagePicker.selectFrom.text) {
            Button("Use the photo library") {
                //Analytics.shared.trackDidSelectAction(actionName: "photo_library")
                // We don't need permissions for this, move on
                imagePickerSource = .photoLibrary
            }
            Button("Cancel", role: .cancel) {
                //Analytics.shared.trackDidSelectAction(actionName: "cancel")
                showConfirmationDialog = false
            }
        }
        .alert(
            settingsAlertTitle,
            isPresented: $showSettingsAlert,
            actions: {
                Button("some text") {
                    showSettingsAlert = false
                    //AppController.shared.openOSSettings()
                }
                Button("some text") {
                    showSettingsAlert = false
                }
            },
            message: {
                Text("text4")
                //Localized.ImagePicker.openSettingsMessage.view
            }
        )
        .sheet(isPresented: showImagePicker) {
            ImagePicker(sourceType: imagePickerSource ?? .photoLibrary, cameraDevice: .rear) { imagePicked in
                if let image = imagePicked {
                    //Analytics.shared.trackDidTapButton(buttonName: "choose")
                    onCompletion(image)
                } else {
                    //Analytics.shared.trackDidTapButton(buttonName: "cancel")
                }
                imagePickerSource = nil
            }
        }
    }
}

struct ImagePickerCoordinator_Previews: PreviewProvider {
    @State
    static var isPresented = true

    static var previews: some View {
        ImagePickerButton { pickedImage in
            print(pickedImage)
        } label: {
            Text("Hit me")
        }
    }
}
