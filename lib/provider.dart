import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendNotification(String token, String title, String body) async {
  final serverKey =
      'AAAAgUUTWes:APA91bH9DcJHYePCEg433vGo2O8LDMP-nAIpa0te8vhpXwjojTqw1BL28M2WglzgIEYa6hGcpZ4Xzi_r98Ra85FZGFPlIIyna2-9YMXuzkYbhHBMgj4yANjAGeX1SbbME8uoiiKlh7OP';
  final url = Uri.parse('https://fcm.googleapis.com/fcm/send');

  final payload = {
    'to': token,
    'notification': {
      'title': title,
      'body': body,
    },
  };

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'key=$serverKey',
  };

  final response = await http.post(
    url,
    headers: headers,
    body: jsonEncode(payload),
  );

  if (response.statusCode == 200) {
    print('Notification sent successfully');
  } else {
    print('Failed to send notification: ${response.body}');
  }
}
