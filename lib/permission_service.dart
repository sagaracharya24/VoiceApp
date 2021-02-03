

import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  bool isGranted;

  Future<bool> _requestPermission(Permission permission) async {
    PermissionStatus result = await permission.request();

    if (result.isGranted) return true;
    /* if (result[permission] == PermissionStatus.granted) {
      return true;
    } */

    return false;
  }

  Future<bool> requestMicrophonePermission() async {
    var granted = await _requestPermission(Permission.microphone);
    if (!granted) {
      print('Permission service was revoked by the user');
      return granted;
    }
    return granted;
  }

  Future<bool> hasMicrophonePermission() async {
    return hasPermission(Permission.microphone);
  }

  Future<bool> hasPermission(Permission permission) async {
    /* var permissionStatus =
        await _permissionHandler.checkPermissionStatus(permission); */
    var status = await permission.status;
    if (status.isGranted)
      isGranted = status.isGranted;
    else
      isGranted = false;

    return isGranted;
  }
}
