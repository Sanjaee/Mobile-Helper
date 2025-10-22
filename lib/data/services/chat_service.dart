import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/api_client.dart';
import '../../core/utils/storage_helper.dart';

class ChatService {
  final String baseUrl = ApiClient.baseUrl;

  Future<List<Map<String, dynamic>>> getChatHistory(String orderId) async {
    try {
      final token = await StorageHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/chats/order/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['messages'] ?? []);
      } else {
        throw Exception('Failed to load chat history');
      }
    } catch (e) {
      print('Error loading chat history: $e');
      throw e;
    }
  }

  Future<void> sendMessage({
    required String orderId,
    required String senderId,
    required String senderType,
    required String message,
  }) async {
    try {
      final token = await StorageHelper.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/chats/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'order_id': orderId,
          'sender_id': senderId,
          'sender_type': senderType,
          'message': message,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }

  Future<int> getUnreadCount(String orderId, String userId) async {
    try {
      final token = await StorageHelper.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/chats/order/$orderId/unread?user_id=$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  Future<void> markAsRead(String orderId, String userId) async {
    try {
      final token = await StorageHelper.getToken();
      await http.patch(
        Uri.parse('$baseUrl/chats/order/$orderId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'user_id': userId}),
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}

