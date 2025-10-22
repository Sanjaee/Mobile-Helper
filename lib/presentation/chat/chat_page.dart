import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../data/services/chat_service.dart';
import '../../data/models/chat_model.dart';
import '../../core/utils/storage_helper.dart';
import '../../core/utils/jwt_utils.dart';
import '../../core/utils/api_client.dart';

class ChatPage extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final String userType; // "client" or "provider"

  const ChatPage({
    Key? key,
    required this.orderId,
    required this.orderNumber,
    required this.userType,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  WebSocketChannel? _channel;
  String _userId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Get user ID from token
      final token = await StorageHelper.getToken();
      if (token != null) {
        final payload = JwtUtils.decode(token);
        setState(() {
          _userId = payload['user_id'] ?? '';
        });
      }

      // Load chat history
      await _loadChatHistory();

      // Connect to WebSocket
      _connectWebSocket();

      // Mark messages as read
      await _chatService.markAsRead(widget.orderId, _userId);
    } catch (e) {
      print('Error initializing chat: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final messages = await _chatService.getChatHistory(widget.orderId);
      setState(() {
        _messages.clear();
        _messages.addAll(messages.map((m) => ChatMessage.fromJson(m)));
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  void _connectWebSocket() {
    try {
      final wsUrl = ApiClient.websocketUrl;
      final url = '$wsUrl/chat/${widget.orderId}?user_id=$_userId';
      
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _channel!.stream.listen(
        (message) {
          final data = json.decode(message);
          if (data['type'] == 'new_message') {
            final chatMessage = ChatMessage.fromJson(data['message']);
            setState(() {
              // Check if message already exists
              if (!_messages.any((m) => m.id == chatMessage.id)) {
                _messages.add(chatMessage);
                _scrollToBottom();
              }
            });
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await _chatService.sendMessage(
        orderId: widget.orderId,
        senderId: _userId,
        senderType: widget.userType,
        message: message,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.userType == 'client' ? Colors.blue : Colors.orange;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat - Order #${widget.orderNumber}'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            'No messages yet.\nStart a conversation!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message.senderId == _userId;
                            
                            return _buildMessageBubble(message, isMe, color);
                          },
                        ),
                ),

                // Message input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          mini: true,
                          backgroundColor: color,
                          onPressed: _sendMessage,
                          child: const Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, Color color) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? color : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

