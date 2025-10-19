import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/api_endpoints.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;
  bool _isConnected = false;
  String? _currentOrderId;

  bool get isConnected => _isConnected;

  // Connect to order WebSocket
  Stream<Map<String, dynamic>> connectToOrder(String orderId) {
    _currentOrderId = orderId;
    _controller = StreamController<Map<String, dynamic>>.broadcast();

    try {
      final wsUrl = '${ApiEndpoints.wsOrders}/$orderId';
      print('🔌 Connecting to Order WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            print('📩 Order WebSocket message received: ${data['type']}');
            _controller!.add(data);
          } catch (e) {
            print('❌ Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('❌ Order WebSocket error: $error');
          _isConnected = false;
          _controller!.addError(error);
        },
        onDone: () {
          print('🔌 Order WebSocket connection closed');
          _isConnected = false;
          _controller!.close();
        },
      );
    } catch (e) {
      print('❌ Failed to connect to Order WebSocket: $e');
      _isConnected = false;
      _controller!.addError(e);
    }

    return _controller!.stream;
  }

  // Connect to location WebSocket
  Stream<Map<String, dynamic>> connectToLocation(String orderId) {
    _currentOrderId = orderId;
    _controller = StreamController<Map<String, dynamic>>.broadcast();

    try {
      final wsUrl = '${ApiEndpoints.wsLocations}/$orderId';
      print('🔌 Connecting to Location WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            print('📩 Location WebSocket message received: ${data['type']}');
            _controller!.add(data);
          } catch (e) {
            print('❌ Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('❌ Location WebSocket error: $error');
          _isConnected = false;
          _controller!.addError(error);
        },
        onDone: () {
          print('🔌 Location WebSocket connection closed');
          _isConnected = false;
          _controller!.close();
        },
      );
    } catch (e) {
      print('❌ Failed to connect to Location WebSocket: $e');
      _isConnected = false;
      _controller!.addError(e);
    }

    return _controller!.stream;
  }

  // Disconnect
  void disconnect() {
    print('🔌 Disconnecting WebSocket for order: $_currentOrderId');
    _channel?.sink.close();
    _controller?.close();
    _isConnected = false;
    _currentOrderId = null;
  }

  // Send message (if needed)
  void send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }
}

