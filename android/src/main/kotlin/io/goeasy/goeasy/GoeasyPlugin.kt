package io.goeasy.goeasy

import androidx.annotation.NonNull
import android.R.attr.data
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.goeasy.GoEasy
import io.goeasy.GResult
import io.goeasy.GoEasyEventListener
import io.goeasy.ConnectEventListener
import io.goeasy.ConnectOptions
import io.goeasy.pubsub.GPubSub
import io.goeasy.pubsub.PubSubMessage
import io.goeasy.pubsub.PublishOptions
import io.goeasy.pubsub.history.HistoryOptions
import io.goeasy.pubsub.history.HistoryResponse
import io.goeasy.pubsub.presence.HereNowOptions
import io.goeasy.pubsub.presence.HereNowResponse
import io.goeasy.pubsub.presence.Member
import io.goeasy.pubsub.presence.PresenceEvent
import io.goeasy.pubsub.presence.SubscribePresenceOptions
import io.goeasy.pubsub.presence.UnSubscribePresenceOptions
import io.goeasy.pubsub.subscribe.SubscribeOptions
import io.goeasy.pubsub.subscribe.UnSubscribeOptions
import java.util.Collections.emptyMap
import java.util.HashMap

/** GoeasyPlugin */
class GoeasyPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

  private val MAIN_HANDLER = Handler(Looper.getMainLooper())
  private val TAG = "flutter"

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "goeasy_flutter_sdk")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "init" -> {
        val host = call.argument<String>("host")
        val appkey = call.argument<String>("appkey")
        if (host == null || appkey == null) {
          result.error("INVALID_ARGUMENT", "Host or appkey is missing", null)
          return
        }
        GoEasy.init(host, appkey, context)
      }

      "connect" -> {
        val id = call.argument<String>("id") as String?
        val data = call.argument<Map<String,Any>>("data") as Map<String,Any>?
        val otp = call.argument<String>("otp") as String?
        val connectOptions = ConnectOptions().apply {
          if (id != null) {
            this.id = id
          }
          if (data != null) {
            this.data = data
          }
          if (otp != null) {
            this.otp = otp
          }
        }
        GoEasy.connect(connectOptions, object : ConnectEventListener() {
          override fun onSuccess(data: GResult<*>) {
            emitEvent("connect.onSuccess", resultToMap(data))
          }
          override fun onFailed(error: GResult<*>) {
            emitEvent("connect.onFailed", resultToMap(error))
          }
          override fun onProgress(attempts: Int) {
            emitEvent("connect.onProgress", attempts)
          }
        })
      }

      "disconnect" -> {
        GoEasy.disconnect(object : GoEasyEventListener() {
          override fun onSuccess(data: GResult<*>) {
            emitEvent("disconnect.onSuccess", resultToMap(data))
          }
          override fun onFailed(error: GResult<*>) {
            emitEvent("disconnect.onFailed", resultToMap(error))
          }
        })
      }

      "subscribe" -> {
        val channel = call.argument<String>("channel") as String
        val presence = call.argument<Map<String,Boolean>>("presence") as Map<String, Any>
        val subscribeOptions = SubscribeOptions(
          channel = channel,
          presence = presence,
          onMessage = { message:PubSubMessage ->
            val map = HashMap<String, Any>()
            map.put("channel", message.channel)
            map.put("content", message.content)
            map.put("time", message.time)
            emitEvent("subscribe.onMessage", map)
          },
          onSuccess = {
            emitEvent("subscribe.onSuccess",HashMap<String, Any>())
          },
          onFailed = { error:GResult<*> ->
            emitEvent("subscribe.onFailed", resultToMap(error))
          }
        )
        GPubSub.subscribe(subscribeOptions)
      }

      "unsubscribe" -> {
        val channel = call.argument<String>("channel") as String
        val unSubscribeOptions = UnSubscribeOptions(
          channel = channel,
          onSuccess = {
            emitEvent("unsubscribe.onSuccess",HashMap<String, Any>())
          },
          onFailed = { error:GResult<*> ->
            emitEvent("unsubscribe.onFailed", resultToMap(error))
          }
        )
        GPubSub.unsubscribe(unSubscribeOptions)
      }

      "subscribePresence" -> {
        val channel = call.argument<String>("channel") as String
        val subscribePresenceOptions = SubscribePresenceOptions(
          channel = channel,
          onPresence = { event: PresenceEvent ->
            val memberMap = convertMemberToMap(event.member)

            val membersListMap = event.members.map { member ->
              convertMemberToMap(member)
            }

            val map = HashMap<String, Any>()
            map.put("channel", channel)
            map.put("action", event.action)
            map.put("amount", event.amount)
            map.put("member",memberMap)
            map.put("members", membersListMap)
            emitEvent("subscribePresence.onPresence",map)
          },
          onSuccess = {
            emitEvent("subscribePresence.onSuccess",HashMap<String, Any>())
          },
          onFailed = { error:GResult<*> ->
            emitEvent("subscribePresence.onFailed", resultToMap(error))
          }
        )
        GPubSub.subscribePresence(subscribePresenceOptions)
      }

      "unSubscribePresence" -> {
        val channel = call.argument<String>("channel") as String
        val unSubscribePresenceOptions = UnSubscribePresenceOptions(
          channel = channel,
          onSuccess = {
            emitEvent("unSubscribePresence.onSuccess",HashMap<String, Any>())
          },
          onFailed = { error:GResult<*> ->
            emitEvent("unSubscribePresence.onFailed", resultToMap(error))
          }
        )
        GPubSub.unsubscribePresence(unSubscribePresenceOptions)
      }

      "hereNow" -> {
        val channel = call.argument<String>("channel") as String
        val limit = call.argument<Int>("limit") as Int?
        val options = HereNowOptions(
          channel = channel,
          limit = limit,
          onSuccess = { data: HereNowResponse ->
            val response = data.content;
            val membersListMap = response.members.map { member ->
              convertMemberToMap(member)
            }

            val contentMap = HashMap<String, Any>()
            contentMap.put("channel", response.channel)
            contentMap.put("amount", response.amount)
            contentMap.put("members", membersListMap)

            val map = HashMap<String, Any>()
            map.put("code", data.code)
            map.put("content", contentMap)

            emitEvent("hereNow.onSuccess",map)
          },
          onFailed = { error:GResult<*> ->
            emitEvent("hereNow.onFailed", resultToMap(error))
          }
        )
        GPubSub.hereNow(options)
      }

      "history" -> {
        val channel = call.argument<String>("channel") as String
        val limit = call.argument<Int>("limit") as Int
        val options = HistoryOptions(
          channel = channel,
          limit = limit,
          onSuccess = { data: HistoryResponse ->
            val map = HashMap<String, Any>()
            val contentMap = HashMap<String, Any>()
            val messagesList = data.content.messages.map { message ->
              val messageMap = HashMap<String, Any>()
              messageMap.put("time",message.time as Long)
              messageMap.put("content",message.content)
              messageMap
            }
            contentMap.put("messages",messagesList);

            map.put("code",data.code)
            map.put("content",contentMap)

            emitEvent("history.onSuccess",map)
          },
          onFailed = { error:GResult<*> ->
            emitEvent("history.onFailed", resultToMap(error))
          }
        )
        GPubSub.history(options)
      }

      "publish" -> {
        val channel = call.argument<String>("channel") as String
        val message = call.argument<String>("message") as String
        val qos = call.argument<String>("qos") as Int?
        val options = PublishOptions(channel,message,qos)
        GPubSub.publish(options, object : GoEasyEventListener() {
          override fun onSuccess(data: GResult<*>) {
            emitEvent("publish.onSuccess", resultToMap(data))
          }
          override fun onFailed(error: GResult<*>) {
            emitEvent("publish.onFailed", resultToMap(error))
          }
        })
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  private fun convertMemberToMap(member: Member): HashMap<String, Any> {
    val mMap = HashMap<String, Any>()

    mMap.put("id",member.id as String)
    member.data?.let {
      val dataMap = HashMap<String, Any>()
      if (it is Map<*, *>) {
        for ((key, value) in it) {
          val stringKey = key as String
          val stringValue = value.toString().replace("\"", "")
          dataMap.put(stringKey,stringValue)
        }
      }
      mMap.put("data",dataMap)
    }
    return mMap
  }

  private fun <T> resultToMap(result: GResult<T>): HashMap<String, Any> {
    val map = HashMap<String, Any>()
    result.code?.let { map.put("code", result.code as Int) }
    result.data?.let { map.put("data", result.data as Any) }
    return map
  }

  private fun <T> emitEvent(
    method: String,
    data: T,
  ) {
    MAIN_HANDLER.post(Runnable {
      channel.invokeMethod(method, data)
    })
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
