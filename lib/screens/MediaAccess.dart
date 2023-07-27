import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

final _firestore = FirebaseFirestore.instance;

Future<void> mediaAccess(User loggedInuser) async {
  final permissionStatus = await Permission.storage.status;
  if (permissionStatus.isDenied) {
    // Here just ask for the permission for the first time
    await Permission.storage.request();

    // I noticed that sometimes popup won't show after the user presses deny
    // so I do the check once again but now go straight to appSetting
    if (permissionStatus.isDenied) {
      await openAppSettings();
    }
  } else if (permissionStatus.isPermanentlyDenied) {
    // Here open app settings for the user to manually enable permission in case
    // where permission was permanently denied
    await openAppSettings();
  } else {
    final ImagePicker _picker = ImagePicker();
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final fileBytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.path.split('/').last;
      final Reference reference =
          FirebaseStorage.instance.ref().child('images/$fileName');

      try {
        // Upload the image to Firebase Storage
        final UploadTask uploadTask = reference.putData(fileBytes);
        await uploadTask.whenComplete(() async {
          // Get the download URL after the image is successfully uploaded
          final imageUrl = await reference.getDownloadURL();

          // Store the download URL in Firestore
          _firestore.collection('messages').add({
            'sender': loggedInuser.email,
            'text': imageUrl,
            'timestamp': Timestamp.now(),
          });
        });
      } catch (e) {
        // Handle any errors that occur during the upload or getting the download URL
        print("Error occurred during upload or getting download URL: $e");
      }
    }
  }
}
