import 'package:flutter/services.dart';
import 'types.dart';

class GoEasy {
  static const MethodChannel _channel = MethodChannel('goeasy_flutter_sdk');
  static Function? _onProgress;
  static final Map<String, SubscribeOptions> _channelMessageMap = {};
  static final Map<String, SubscribePresenceOptions> _channelPresenceMap = {};
  static final Map<String, CallBackOptions> _optionMap = {};

  static Future<void> init(String host, String appkey) async {
    await _channel.invokeMethod('init', {'host': host, 'appkey': appkey});
  }

  static Future<void> connect(ConnectOptions options, ConnectEventListener listener) async {
    _onProgress = listener.onProgress;
    _setMethodCallHandler('connect',listener);
    await _channel.invokeMethod('connect', {
      'id': options.id,
      'data': options.data,
      'otp': options.otp,
    });
  }

  static Future<void> disconnect(GoEasyEventListener listener) async {
    _setMethodCallHandler('disconnect',listener);
    await _channel.invokeMethod('disconnect');
  }

  static Future<void> subscribe(SubscribeOptions options) async {
    if (options.channel != null ) {
      _channelMessageMap[options.channel as String] = options;
    }
    if (options.channels != null) {
      options.channels?.map((channel) {
        _channelMessageMap[channel] = options;
      });
    }
    _setMethodCallHandler('subscribe',options);
    await _channel.invokeMethod('subscribe', {
      'channel': options.channel,
      'channels': options.channels,
      'presence': options.presence,
    });
  }

  static Future<void> unsubscribe(UnSubscribeOptions options) async {
    _setMethodCallHandler('unsubscribe',options);
    await _channel.invokeMethod('unsubscribe', {
      'channel': options.channel
    });
  }

  static Future<void> subscribePresence(SubscribePresenceOptions options) async {
    _channelPresenceMap[options.channel] = options;
    _setMethodCallHandler('subscribePresence',options);
    await _channel.invokeMethod('subscribePresence', {
      'channel': options.channel,
      'membersLimit': options.membersLimit
    });
  }

  static Future<void> unSubscribePresence(UnSubscribePresenceOptions options) async {
    _setMethodCallHandler('unSubscribePresence',options);
    await _channel.invokeMethod('unSubscribePresence', {
      'channel': options.channel
    });
  }

  static Future<void> hereNow(HereNowOptions options) async {
    _setMethodCallHandler('hereNow',options);
    await _channel.invokeMethod('hereNow', {
      'channel': options.channel,
      'limit': options.limit
    });
  }

  static Future<void> history(HistoryOptions options) async {
    _setMethodCallHandler('history',options);
    await _channel.invokeMethod('history', {
      'channel': options.channel,
      'start': options.start,
      'end': options.end,
      'limit': options.limit
    });
  }

  static Future<void> publish(PublishOptions options, GoEasyEventListener listener) async {
    _setMethodCallHandler('publish',listener);
    await _channel.invokeMethod('publish', {
      'channel': options.channel,
      'message': options.message,
      'qos': options.qos
    });
  }

  static void _setMethodCallHandler(String name, CallBackOptions option) {
    _optionMap[name] = option;

    _channel.setMethodCallHandler((call) async {
      String operationName = '';
      String callbackType = '';
      CallBackOptions? options;
      final parts = call.method.split('.');
      if (parts.length == 2) {
        operationName = parts[0];
        callbackType = parts[1];
        options = _optionMap[operationName];
      } else {
        print('Invalid method call format: ${call.method}');
        return;
      }

      switch (callbackType) {
        case 'onProgress':
          _onProgress?.call(call.arguments as int);
          break;
        case 'onMessage':
          final Map<String, dynamic> argumentsMap = Map<String, dynamic>.from(call.arguments as Map);
          final message = PubSubMessage.fromMap(argumentsMap);
          print('sdk: onMessage message: ${message}');
          var messageOption = _channelMessageMap[message.channel];
          messageOption?.onMessage.call(message);
          break;
        case 'onPresence':
          final Map<String, dynamic> argumentsMap = Map<String, dynamic>.from(call.arguments as Map);
          final id = argumentsMap['member']['id'] as String;
          final channel = argumentsMap['channel'] as String;
          final data = Map<String, dynamic>.from(argumentsMap['member']['data'] as Map);
          final member = Member(id: id, data: data);
          final membersList = (argumentsMap['members'] as List).map((member) {
            final id = member['id'] as String;
            final data = Map<String, dynamic>.from(member['data'] as Map);
            return Member(id: id, data: data);
          }).toList();
          final event = PresenceEvent(
              action: argumentsMap['action'],
              member: member,
              amount: argumentsMap['amount'],
              members: membersList
          );
          var channelPresence = _channelPresenceMap[channel];
          channelPresence?.onPresence.call(event);
          break;
        case 'onSuccess':
          final Map<String, dynamic> argumentsMap = Map<String, dynamic>.from(call.arguments as Map);
          print('sdk: onSuccess+++++ map: ${argumentsMap}');
          if (options is GoEasyEventListener) {
            final result = GResult.fromMap(argumentsMap);
            options.onSuccess.call(result);
          } else if (options is HereNowOptions) {
            final code = argumentsMap['code'];
            final content = argumentsMap['content'];
            final membersList = (content['members'] as List).map((member) {
              final id = member['id'] as String;
              final data = Map<String, dynamic>.from(member['data'] as Map);
              return Member(id: id, data: data);
            }).toList();

            HereNowResponse hereNowResponse = HereNowResponse(
                code: code,
                content: PresenceContent(
                  amount: content['amount'],
                  channel: content['channel'],
                  members: membersList,
                )
            );
            print('sdk: HereNowResponse+++++ hereNowResponse: ${hereNowResponse}');
            options.onSuccess.call(hereNowResponse);

          } else if (options is HistoryOptions) {
            final code = argumentsMap['code'];
            final content = argumentsMap['content'];
            final messageList = (content['messages'] as List).map((message) {
              final messageMap = Map<String, dynamic>.from(message as Map);
              return HistoryMessage(
                  time: messageMap['time'],
                  content: messageMap['content']
              );
            }).toList();

            final historyContent = HistoryContent(messages: messageList);
            final result = HistoryResponse(code: code, content: historyContent);
            print('sdk: onSuccess+++++ HereNowResponse: ${result}');
            options.onSuccess.call(result);

          } else {
            options?.onSuccess.call(null);
          }
          break;
        case 'onFailed':
          final Map<String, dynamic> argumentsMap = Map<String, dynamic>.from(call.arguments as Map);
          print('sdk: onFailed+++++: ${argumentsMap}');
          final result = GResult.fromMap(argumentsMap);
          print('sdk: onFailed+++++: ${result}');
          options?.onFailed.call(result);
          break;
        default:
          print('Unknown method: ${call.method}');
      }
      return null;
    });
  }
}
