import Flutter
import UIKit
import GoEasySwift

public class SwiftGoeasyPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(name: "goeasy_flutter_sdk", binaryMessenger: registrar.messenger())
      let instance = SwiftGoeasyPlugin()
      instance.channel = channel
      registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
          case "init":
              guard let args = call.arguments as? [String: Any],
                    let host = args["host"] as? String,
                    let appkey = args["appkey"] as? String else {
                        result(FlutterError(code: "INVALID_ARGUMENT", message: "Host or appkey is missing", details: nil))
                        return
                    }
              GoEasy.initGoEasy(host: host, appkey: appkey)
              result("GoEasy initialized")

          case "connect":
              guard let args = call.arguments as? [String: Any] else {
                  result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments are missing", details: nil))
                  return
              }

              let id = args["id"] as? String
              let data = args["data"] as? [String: String]
              let otp = args["otp"] as? String

              let connectOptions = ConnectOptions()
              if let id = id {
                  connectOptions.id = id
              }
              if let data = data {
                  connectOptions.data = data
              }
              if let otp = otp {
                  connectOptions.otp = otp
              }

              let connectEventListener = ConnectEventListener()
              connectEventListener.onSuccess = { result in
                  self.emitEvent(method: "connect.onSuccess", data: self.resultToMap(result: result))
              }
              connectEventListener.onFailed = { error in
                  self.emitEvent(method: "connect.onFailed", data: self.resultToMap(result: error))
              }
              connectEventListener.onProgress = { attempts in
                  self.emitEvent(method: "connect.onProgress", data: attempts)
              }
              GoEasy.connect(options: connectOptions, connectEventListener: connectEventListener)
              break

          case "disconnect":
              let disconnectEventListener = GoEasyEventListener()
              disconnectEventListener.onSuccess = { result in
                  self.emitEvent(method: "disconnect.onSuccess", data: self.resultToMap(result: result))
              }
              disconnectEventListener.onFailed = { error in
                  self.emitEvent(method: "disconnect.onFailed", data: self.resultToMap(result: error))
              }
              GoEasy.disconnect(disconnectEventListener: disconnectEventListener)
              break

          case "subscribe":
              guard let args = call.arguments as? [String: Any] else {
                  return
              }
              let channel = args["channel"] as? String
              let channels = args["channels"] as? Array<String>
              let presence = args["presence"] as? [String: Bool]

              let subscribeOption = SubscribeOptions(
                  channel: channel ?? "",
                  channels: channels,
                  presence: presence ?? ["enable": false],
                  onMessage: { message in
                      var map = [String: Any]()
                      map["channel"] = message.channel
                      map["content"] = message.content
                      map["time"] = message.time
                      self.emitEvent(method: "subscribe.onMessage", data: map)
                  },
                  onSuccess: {
                      self.emitEvent(method: "subscribe.onSuccess", data: [String: Any]())
                  },
                  onFailed: { error in
                      self.emitEvent(method: "subscribe.onFailed", data: self.resultToMap(result: error))
                  }
              )
              GPubSub.subscribe(options: subscribeOption)
              break

          case "unsubscribe":
              guard let arguments = call.arguments as? [String: Any],
                    let channel = arguments["channel"] as? String else {
                  result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'channel' argument", details: nil))
                  return
              }
              let unsubscribeOption = UnSubscribeOptions(
                  channel: channel,
                  onSuccess:{
                      self.emitEvent(method: "unsubscribe.onSuccess", data: [String: Any]())
                  },
                  onFailed:{ error in
                      self.emitEvent(method: "unsubscribe.onFailed", data: self.resultToMap(result: error))
                  }
              )
              GPubSub.unsubscribe(options: unsubscribeOption)
              break

          case "subscribePresence":
              guard let arguments = call.arguments as? [String: Any],
                    let channel = arguments["channel"] as? String else {
                  result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'channel' argument", details: nil))
                  return
              }
              let membersLimit = arguments["membersLimit"] as? Int
              let option = SubscribePresenceOptions(
                  channel: channel,
                  membersLimit: membersLimit,
                  onPresence: { event in
                      let memberMap = self.convertMemberToMap(member: event.member)

                      let membersListMap = event.members.map { member -> [String: Any] in
                          return self.convertMemberToMap(member: member)
                      }

                      var map = [String: Any]()
                      map["channel"] = channel
                      map["action"] = event.action
                      map["amount"] = event.amount
                      map["member"] = memberMap
                      map["members"] = membersListMap

                      self.emitEvent(method: "subscribePresence.onPresence", data: map)
                  },
                  onSuccess:{
                      self.emitEvent(method: "subscribePresence.onSuccess", data: [String: Any]())
                  },
                  onFailed:{ error in
                      self.emitEvent(method: "subscribePresence.onFailed", data: self.resultToMap(result: error))
                  }
              )
              GPubSub.subscribePresence(options: option)
              break

          case "unSubscribePresence":
              guard let arguments = call.arguments as? [String: Any],
                    let channel = arguments["channel"] as? String else {
                  result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'channel' argument", details: nil))
                  return
              }
              let option = UnSubscribePresenceOptions(
                  channel: channel,
                  onSuccess:{
                      self.emitEvent(method: "unSubscribePresence.onSuccess", data: [String: Any]())
                  },
                  onFailed:{ error in
                      self.emitEvent(method: "unSubscribePresence.onFailed", data: self.resultToMap(result: error))
                  }
              )
              GPubSub.unsubscribePresence(options: option)
              break

          case "hereNow":
              guard let arguments = call.arguments as? [String: Any],
                    let channel = arguments["channel"] as? String else {
                  result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'channel' argument", details: nil))
                  return
              }
              let limit = arguments["limit"] as? Int
              let option = HereNowOptions(
                  channel: channel,
                  limit: limit,
                  onSuccess:{ data in
                      let response = data.content
                      let membersListMap = response.members.map { member -> [String: Any] in
                          return self.convertMemberToMap(member: member)
                      }

                      var contentMap = [String: Any]()
                      contentMap["channel"] = response.channel
                      contentMap["amount"] = response.amount
                      contentMap["members"] = membersListMap

                      var map = [String: Any]()
                      map["code"] = data.code
                      map["content"] = contentMap

                      self.emitEvent(method: "hereNow.onSuccess", data: map)
                  },
                  onFailed:{ error in
                      self.emitEvent(method: "hereNow.onFailed", data: self.resultToMap(result: error))
                  }
              )
              GPubSub.hereNow(options: option)
              break

          case "history":
              guard let arguments = call.arguments as? [String: Any],
                    let channel = arguments["channel"] as? String else {
                  result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'channel' argument", details: nil))
                  return
              }
              let start = arguments["limit"] as? Int64
              let end = arguments["end"] as? Int64
              let limit = arguments["limit"] as? Int
              let option = HistoryOptions(
                  channel: channel,
                  start: start,
                  end: end,
                  limit: limit,
                  onSuccess:{ data in
                      var map = [String: Any]()
                      var contentMap = [String: Any]()

                      let messagesList = data.content.messages.map { message -> [String: Any] in
                          var messageMap = [String: Any]()
                          messageMap["time"] = message.time
                          messageMap["content"] = message.content
                          return messageMap
                      }
                      contentMap["messages"] = messagesList

                      map["code"] = data.code
                      map["content"] = contentMap

                      self.emitEvent(method: "history.onSuccess", data: map)
                  },
                  onFailed:{ error in
                      self.emitEvent(method: "history.onFailed", data: self.resultToMap(result: error))
                  }
              )
              GPubSub.history(options: option)
              break

          case "publish":
              guard let arguments = call.arguments as? [String: Any],
                    let channel = arguments["channel"] as? String,
                    let message = arguments["message"] as? String ,
                    let qos = arguments["qos"] as? Int32 else {
                  result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing 'channel' argument", details: nil))
                  return
              }
              let publishEventListener = GoEasyEventListener()
              publishEventListener.onSuccess = { result in
                  self.emitEvent(method: "publish.onSuccess", data: self.resultToMap(result: result))
              }
              publishEventListener.onFailed = { error in
                  self.emitEvent(method: "publish.onFailed", data: self.resultToMap(result: error))
              }
              let options = PublishOptions(channel: channel, message: message, qos: qos)
              GPubSub.publish(options: options, publishEventListener: publishEventListener)
              break

          default:
              result(FlutterMethodNotImplemented)
      }

  }

  private func convertMemberToMap(member: Member) -> [String: Any] {
      var mMap = [String: Any]()
      mMap["id"] = member.id

      var dataMap = [String: Any]()
      for (key, value) in member.data {
          let stringKey = key
          let stringValue = "\(value)"
          dataMap[stringKey] = stringValue
      }
      mMap["data"] = dataMap

      return mMap
  }

  private func emitEvent<T>(method: String, data: T) {
      channel?.invokeMethod(method, arguments: data)
  }

  private func resultToMap(result: GResult) -> [String: Any] {
      var map = [String: Any]()
      map["code"] = result.code
      map["data"] = result.data
      return map
  }
}
