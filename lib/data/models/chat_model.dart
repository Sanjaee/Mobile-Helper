class ChatMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String senderType; // "client" or "provider"
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderType,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderType: json['sender_type'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'sender_id': senderId,
      'sender_type': senderType,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  bool get isFromClient => senderType == 'client';
  bool get isFromProvider => senderType == 'provider';
}

