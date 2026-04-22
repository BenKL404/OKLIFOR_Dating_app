import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/oklifor_api_config.dart';
import '../../../core/api/models/chat_api_models.dart';

class ChatPresenceEvent {
  final String threadId;
  final String userId;
  final bool online;
  final int? lastSeenEpoch;

  const ChatPresenceEvent({
    required this.threadId,
    required this.userId,
    required this.online,
    this.lastSeenEpoch,
  });
}

class ChatTypingEvent {
  final String threadId;
  final String userId;
  final bool typing;

  const ChatTypingEvent({
    required this.threadId,
    required this.userId,
    required this.typing,
  });
}

class ChatReadReceiptEvent {
  final String threadId;
  final String userId;
  final int readAtEpoch;

  const ChatReadReceiptEvent({
    required this.threadId,
    required this.userId,
    required this.readAtEpoch,
  });
}

class ChatWebSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  final _messagesController = StreamController<ChatMessagePayload>.broadcast();
  final _presenceController = StreamController<ChatPresenceEvent>.broadcast();
  final _typingController = StreamController<ChatTypingEvent>.broadcast();
  final _readReceiptController =
      StreamController<ChatReadReceiptEvent>.broadcast();
  final _errorsController = StreamController<String>.broadcast();
  final _subscribedController = StreamController<String>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final Set<String> _subscribedThreads = <String>{};
  bool _connected = false;
  String? _lastToken;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  Stream<ChatMessagePayload> get messages => _messagesController.stream;
  Stream<ChatPresenceEvent> get presence => _presenceController.stream;
  Stream<ChatTypingEvent> get typing => _typingController.stream;
  Stream<ChatReadReceiptEvent> get readReceipts => _readReceiptController.stream;
  Stream<String> get errors => _errorsController.stream;
  Stream<String> get subscribed => _subscribedController.stream;
  Stream<bool> get connectionState => _connectionStateController.stream;
  bool get isConnected => _connected;

  Future<void> connect({required String accessToken}) async {
    if (_disposed) return;
    _lastToken = accessToken;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_disposed || _lastToken == null) return;
    
    await _cleanupSocket();
    
    final wsUri = _buildWsUri(_lastToken!);
    try {
      _channel = WebSocketChannel.connect(wsUri);
      _sub = _channel!.stream.listen(
        (raw) {
          if (raw is! String) return;
          final json = jsonDecode(raw);
          if (json is! Map<String, dynamic>) return;
          final type = (json['type'] as String?) ?? '';
          
          if (type == 'message') {
            final msg = json['message'];
            if (msg is Map<String, dynamic>) {
              final payload = ChatMessagePayload.fromJson(msg);
              _messagesController.add(payload);
            }
          } else if (type == 'subscribed') {
            final threadId = (json['threadId'] as String?) ?? '';
            if (threadId.isNotEmpty) {
              _subscribedThreads.add(threadId);
              _subscribedController.add(threadId);
            }
          } else if (type == 'error') {
            final code = (json['code'] as String?) ?? 'ws_error';
            _errorsController.add(code);
          } else if (type == 'presence') {
            _presenceController.add(
              ChatPresenceEvent(
                threadId: (json['threadId'] as String?) ?? '',
                userId: (json['userId'] as String?) ?? '',
                online: (json['online'] as bool?) ?? false,
                lastSeenEpoch: json['lastSeenEpoch'] is int
                    ? json['lastSeenEpoch'] as int
                    : (json['lastSeenEpoch'] is num
                          ? (json['lastSeenEpoch'] as num).toInt()
                          : null),
              ),
            );
          } else if (type == 'typing') {
            _typingController.add(
              ChatTypingEvent(
                threadId: (json['threadId'] as String?) ?? '',
                userId: (json['userId'] as String?) ?? '',
                typing: (json['typing'] as bool?) ?? false,
              ),
            );
          } else if (type == 'read_receipt') {
            final epoch = json['readAtEpoch'];
            _readReceiptController.add(
              ChatReadReceiptEvent(
                threadId: (json['threadId'] as String?) ?? '',
                userId: (json['userId'] as String?) ?? '',
                readAtEpoch: epoch is int
                    ? epoch
                    : (epoch is num ? epoch.toInt() : 0),
              ),
            );
          }
        },
        onDone: () => _handleDisconnect(),
        onError: (_) => _handleDisconnect(),
      );
      
      _connected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);
      _startHeartbeat();
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (_connected) {
      _connected = false;
      _connectionStateController.add(false);
    }
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectTimer?.isActive == true) return;
    
    _reconnectAttempts++;
    final delay = Duration(seconds: (_reconnectAttempts * 2).clamp(2, 30));
    _reconnectTimer = Timer(delay, () {
      if (!_connected && !_disposed) {
        _doConnect();
      }
    });
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_connected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'action': 'ping'}));
        } catch (_) {
          _handleDisconnect();
        }
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _cleanupSocket() async {
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> subscribeThread(String threadId) async {
    final c = _channel;
    if (!_connected || c == null) {
      throw StateError('websocket_non_connecte');
    }
    _channel!.sink.add(
      jsonEncode({'action': 'subscribe', 'threadId': threadId}),
    );
  }

  Future<void> subscribeThreadAndWait(
    String threadId, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    await subscribeThread(threadId);
    if (_subscribedThreads.contains(threadId)) return;

    await subscribed.firstWhere(
      (t) => t == threadId,
      orElse: () => '',
    ).timeout(timeout);

    if (!_subscribedThreads.contains(threadId)) {
      throw TimeoutException('subscribe_timeout', timeout);
    }
  }

  Future<void> sendMessage({
    required String threadId,
    required String kind,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    int? voiceSeconds,
    String? locationLabel,
    String? fileUrl,
  }) async {
    final c = _channel;
    if (!_connected || c == null) {
      throw StateError('websocket_non_connecte');
    }
    c.sink.add(
      jsonEncode({
        'action': 'send',
        'threadId': threadId,
        'kind': kind,
        'text': text,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'audioUrl': audioUrl,
        'voiceSeconds': voiceSeconds,
        'locationLabel': locationLabel,
        'fileUrl': fileUrl,
      }),
    );
  }

  Future<void> markRead({required String threadId}) async {
    final c = _channel;
    if (!_connected || c == null) {
      throw StateError('websocket_non_connecte');
    }
    c.sink.add(jsonEncode({'action': 'markRead', 'threadId': threadId}));
  }

  Future<void> sendTyping({
    required String threadId,
    required bool typing,
  }) async {
    final c = _channel;
    if (!_connected || c == null) {
      throw StateError('websocket_non_connecte');
    }
    c.sink.add(
      jsonEncode({'action': 'typing', 'threadId': threadId, 'typing': typing}),
    );
  }

  Future<void> disconnect() async {
    _connected = false;
    _lastToken = null;
    _subscribedThreads.clear();
    await _cleanupSocket();
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _messagesController.close();
    await _presenceController.close();
    await _typingController.close();
    await _readReceiptController.close();
    await _errorsController.close();
    await _subscribedController.close();
    await _connectionStateController.close();
  }

  static Uri _buildWsUri(String token) {
    final base = Uri.parse(OkliforApiConfig.baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/ws/chat',
      queryParameters: {'token': token},
    );
  }
}
