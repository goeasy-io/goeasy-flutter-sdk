import 'package:flutter/material.dart';
import 'dart:io' show Platform;

import 'package:goeasy/goeasy.dart';
import 'package:goeasy/types.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _responseFromAndroid = 'No response yet';
  String _messageFromAndroid = 'No message yet';
  String _sendMessageResult = 'No message sent yet';

  @override
  void initState() {
    super.initState();

    connect();
    subscribe();

  }

  void initGoEasy() {
    GoEasy.init('hangzhou.goeasy.io', 'BC-xxxx');
  }

  void connect() {
    initGoEasy();
    String id;
    Map<String, dynamic> data;

    if (Platform.isAndroid) {
      print("Running on Android");
      id = 'user001';
      data = {'nickname': 'android', 'avatar': '/static/images/6.png'};
    } else if (Platform.isIOS) {
      print("Running on iOS");
      id = 'user002';
      data = {'nickname': 'ios', 'avatar': '/static/images/7.png'};
    } else {
      id = 'unknown';
      data = {'nickname': 'unknown', 'avatar': '/static/images/default.png'};
    }
    ConnectOptions options = ConnectOptions(id: id, data: data);
    ConnectEventListener listener = ConnectEventListener(
      onSuccess: (data) {
        print('demo: onSuccess...${data.code}${data.data}');
        setState(() {
          _responseFromAndroid = "connect success";
        });
      },
      onProgress: (attempts) {
        print('demo: onProgress...${attempts}');
      },
      onFailed: (error) {
        print('demo: onFailed....${error.code}${error.data}');
      }
    );
    GoEasy.connect(options,listener);
  }

  void disconnect() {
    GoEasyEventListener listener = GoEasyEventListener(
      onSuccess: (data) {
        print('demo: disconnect onSuccess...${data.code}${data.data}');
        setState(() {
          _responseFromAndroid = "disconnect success";
        });
      },
      onFailed: (error) {
        print('demo: disconnect onFailed....${error.code}${error.data}');
      }
    );
    GoEasy.disconnect(listener);
  }

  void subscribe() {
    SubscribeOptions options = SubscribeOptions(
      channel: "test_channel",
      presence: {"enable":true},
      onMessage: (message) {
        print('demo: onMessage...channel:${message.channel},content:${message.content},time:${message.time}');
        setState(() {
          _messageFromAndroid = message as String;
        });
      },
      onSuccess: (data) {
        print('demo: subscribe onSuccess...');
        setState(() {
          _responseFromAndroid = "subscribe success";
        });
      },
      onFailed: (error) {
        print('demo: subscribe onFailed....${error.code}${error.data}');
      }
    );
    GoEasy.subscribe(options);
  }

  void unsubscribe() {
    UnSubscribeOptions options = UnSubscribeOptions(
      channel: "test_channel",
      onSuccess: (data) {
        print('demo: unsubscribe onSuccess...');
        setState(() {
          _responseFromAndroid = "unsubscribe success";
        });
      },
      onFailed: (error) {
        print('demo: unsubscribe onFailed....${error.code}${error.data}');
      }
    );
    GoEasy.unsubscribe(options);
  }

  void subscribePresence() {
    SubscribePresenceOptions options = SubscribePresenceOptions(
      channel: "test_channel",
      onPresence: (event) {
        print('demo: onPresence...action:${event.action}..amount:${event.amount}');
        print('demo: onPresence...Member:${event.member.id}..data:${event.member.data}');
        print('demo: onPresence...Members:${event.members}');
      },
      onSuccess: (data) {
        print('demo: subscribePresence onSuccess...');
        setState(() {
          _responseFromAndroid = "subscribePresence success";
        });
      },
      onFailed: (error) {
        print('demo: unsubscribe onFailed....${error.code}${error.data}');
      }
    );
    GoEasy.subscribePresence(options);
  }

  void unSubscribePresence() {
    UnSubscribePresenceOptions options = UnSubscribePresenceOptions(
      channel: "test_channel",
      onSuccess: (data) {
        print('demo: unSubscribePresence onSuccess...');
        setState(() {
          _responseFromAndroid = "unSubscribePresence success";
        });
      },
      onFailed: (error) {
        print('demo: unSubscribePresence onFailed....${error.code}${error.data}');
      }
    );
    GoEasy.unSubscribePresence(options);
  }

  void hereNow() {
    HereNowOptions options = HereNowOptions(
      channel: 'test_channel',
      onSuccess: (data) {
        print('demo: hereNow onSuccess...');
        print('demo: hereNow amount...${data.content.amount}');
        print('demo: hereNow members...${data.content.members}');
        List<Member> members = data.content.members;
        for (var member in members) {
          print('Member id: ${member.id}, data: ${member.data}');
        }
        setState(() {
          _responseFromAndroid = "hereNow success";
        });
      },
      onFailed: (error) {
        print('demo: hereNow onFailed....${error.code}${error.data}');
      }
    );
    GoEasy.hereNow(options);
  }

  void history() {
    HistoryOptions options = HistoryOptions(
      channel: 'test_channel',
      limit: 10,
      onSuccess: (data) {
        print('demo: history onSuccess...');
        List<HistoryMessage> messages = data.content.messages;
        for (var message in messages) {
          print('message time: ${ message.time}, content: ${ message.content}');
        }
        setState(() {
          _responseFromAndroid = "history success";
        });
      },
      onFailed: (error) {
        print('demo: history onFailed....${error.code}${error.data}');
      }
    );
    GoEasy.history(options);
  }

  void sendMessage([String? message]) {
    PublishOptions options = PublishOptions(channel: "test_channel", message: message as String);

    GoEasyEventListener listener = GoEasyEventListener(
      onSuccess: (data) {
        print('demo: sendMessage onSuccess...${data.code}${data.data}');
        setState(() {
          _sendMessageResult = "sendMessage success";
        });
      },
      onFailed: (error) {
        print('demo: sendMessage onFailed....${error.code}${error.data}');
      }
    );
    GoEasy.publish(options, listener);
  }


  @override
  Widget build(BuildContext context) {
    TextEditingController messageController = TextEditingController();

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Response: $_responseFromAndroid',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'onMessage: $_messageFromAndroid',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Send Message Result: $_sendMessageResult',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => connect(),
                    child: const Text('连接'),
                  ),
                  ElevatedButton(
                    onPressed: () => disconnect(),
                    child: const Text('断开连接'),
                  ),
                  ElevatedButton(
                    onPressed: () => subscribe(),
                    child: const Text('订阅'),
                  ),
                  ElevatedButton(
                    onPressed: () => unsubscribe(),
                    child: const Text('取消订阅'),
                  ),
                  ElevatedButton(
                    onPressed: () => subscribePresence(),
                    child: const Text('订阅上下线'),
                  ),
                  ElevatedButton(
                    onPressed: () => unSubscribePresence(),
                    child: const Text('取消订阅上下线'),
                  ),
                  ElevatedButton(
                    onPressed: () => hereNow(),
                    child: const Text('hereNow'),
                  ),
                  ElevatedButton(
                    onPressed: () => history(),
                    child: const Text('历史消息'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: '发送消息：',
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => sendMessage(messageController.text),
                child: const Text('发送'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
