import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/services/api_services.dart';

class NotificationHandler {
  getNotifications() async {
    try {
      Strings.notifications = await ApiService().getRequest(
        "notifications/${Strings.userId}",
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendNotification({
    required List<Map<String, String>> notifications,
  }) async {
    try {
      final response = await ApiService().postRequest(
        "notifications",
        notifications,
      );

      if (response == 201) {
        print('Notifications sent successfully');
      } else {
        print('Failed to send notifications: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }
}
