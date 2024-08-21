
class GResult {
  final int code;
  final Object data;

  GResult({required this.code,required this.data});

  factory GResult.fromMap(Map<String, dynamic> map) {
    return GResult(
      code: map['code'] as int,
      data: map['data'] as Object,
    );
  }
}

class CallBackOptions<T> {
  final void Function(T) onSuccess;
  final void Function(GResult) onFailed;

  CallBackOptions({
    void Function(T)? onSuccess,
    void Function(GResult)? onFailed,
  }): onSuccess = onSuccess ?? ((_) {}),
        onFailed = onFailed ?? ((_) {});
}

class GoEasyEventListener extends CallBackOptions<GResult> {
  final void Function(GResult) onSuccess;
  final void Function(GResult) onFailed;

  GoEasyEventListener({
    void Function(GResult)? onSuccess,
    void Function(GResult)? onFailed,
  })  : onSuccess = onSuccess ?? ((_) {}),
        onFailed = onFailed ?? ((_) {});
}

class ConnectEventListener extends GoEasyEventListener {
  final void Function(int) onProgress;

  ConnectEventListener({
    super.onSuccess,
    super.onFailed,
    void Function(int)? onProgress,
  })  : onProgress = onProgress ?? ((_) {});
}

class ConnectOptions {
  final String? id;
  final Map<String, dynamic>? data;
  final String? otp;

  ConnectOptions({this.id, this.data, this.otp});
}


class PubSubMessage {
  final String channel;
  final String content;
  final int time;
  PubSubMessage({required this.channel,required this.content,required this.time});

  factory PubSubMessage.fromMap(Map<String, dynamic> map) {
    return PubSubMessage(
      channel: map['channel'] as String,
      content: map['content'] as String,
      time: map['time'] as int,
    );
  }
}

class SubscribeOptions extends CallBackOptions {
  final String? channel;
  final List<String>? channels;
  final Map<String, dynamic> presence;
  final void Function(PubSubMessage) onMessage;

  SubscribeOptions({
    this.channel,
    this.channels,
    Map<String, dynamic>? presence,
    void Function(PubSubMessage)? onMessage,
    void Function(dynamic)? onSuccess,
    super.onFailed,
  }): presence = presence ?? {"enable": false},
    onMessage = onMessage ?? ((_) {}),
    super(onSuccess: onSuccess);
}

class UnSubscribeOptions extends CallBackOptions {
  final String channel;
  UnSubscribeOptions({required this.channel, super.onSuccess, super.onFailed});
}

class Member {
  final String id;
  final Map<String, dynamic>? data;

  Member({required this.id, this.data});

  factory Member.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String;
    final data = Map<String, dynamic>.from(map['data'] as Map);
    return Member(
        id: id,
        data: data
    );
  }
}

class PresenceEvent {
  final String action;
  final Member member;
  final int amount;
  final List<Member> members;

  PresenceEvent({required this.action, required this.member, required this.amount, required this.members});
}

class SubscribePresenceOptions extends CallBackOptions {
  final String channel;
  final int? membersLimit;
  void Function(PresenceEvent) onPresence;

  SubscribePresenceOptions({
    required this.channel,
    this.membersLimit,
    super.onSuccess,
    super.onFailed,
    void Function(PresenceEvent)? onPresence
  }):onPresence =  onPresence?? ((_) {});
}

class UnSubscribePresenceOptions extends CallBackOptions {
  final String channel;
  UnSubscribePresenceOptions({required this.channel, super.onSuccess, super.onFailed});
}

class HereNowResponse {
  final int code;
  final PresenceContent content;

  HereNowResponse({required this.code, required this.content});

  factory HereNowResponse.fromMap(Map<String, dynamic> map) {
    return HereNowResponse(
        code: map['code'] as int,
        content: PresenceContent.fromMap(map['content'])
    );
  }
}

class PresenceContent {
  final int amount;
  final String channel;
  final List<Member> members;

  PresenceContent({required this.amount, required this.channel, required this.members});

  factory PresenceContent.fromMap(Map<String, dynamic> map) {
    print('Parsing PresenceContent from map: $map');
    final amount = map['amount'] as int;
    final channel = map['channel'] as String;
    final membersList = (map['members'] as List).map((member) {
      final memberMap = Map<String, dynamic>.from(member as Map);
      return Member.fromMap(memberMap);
    }).toList();
    return PresenceContent(amount: amount, channel: channel, members: membersList);
  }
}

class HereNowOptions extends CallBackOptions<HereNowResponse> {
  final String channel;
  final int? limit;

  HereNowOptions({
    required this.channel,
    this.limit,
    void Function(HereNowResponse)? onSuccess,
    void Function(GResult)? onFailed,
  }) : super(
    onSuccess: onSuccess,
    onFailed: onFailed,
  );
}

class HistoryMessage {
  final int time;
  final String content;
  HistoryMessage({required this.time,required this.content});
}

class HistoryContent {
  final List<HistoryMessage> messages;
  HistoryContent({required this.messages});
}

class HistoryResponse {
  final int code;
  final HistoryContent content;
  HistoryResponse({required this.code,required this.content});
}

class HistoryOptions extends CallBackOptions<HistoryResponse> {
  final String channel;
  final int? start;
  final int? end;
  final int? limit;

  HistoryOptions({
    required this.channel,
    this.start,
    this.end,
    this.limit=10,
    void Function(HistoryResponse)? onSuccess,
    void Function(GResult)? onFailed,
  }) : super(
    onSuccess: onSuccess,
    onFailed: onFailed,
  );
}

class PublishOptions {
  final String channel;
  final String message;
  final int? qos;

  PublishOptions({required this.channel,required this.message,this.qos=0});
}
