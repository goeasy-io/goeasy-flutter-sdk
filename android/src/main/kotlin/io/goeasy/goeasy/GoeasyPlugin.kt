package io.goeasy.goeasy

import androidx.annotation.NonNull
import android.R.attr.data
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
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
    Log.d(TAG, "onMethodCall: ${call.method}");
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
        Log.i(TAG, "kt: connect -- id-${id} data-${data} otp-${otp}")
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
            Log.i(TAG, "kt: connect onSuccess")
            emitEvent("connect.onSuccess", resultToMap(data))
          }
          override fun onFailed(error: GResult<*>) {
            Log.i(TAG, "kt: Failed to connect GoEasy, code: ${error.code}, error: ${error.data}")
            emitEvent("connect.onFailed", resultToMap(error))

          }
          override fun onProgress(attempts: Int) {
            Log.i(TAG, "kt: onProgress attempts: $attempts")
            emitEvent("connect.onProgress", attempts)
          }
        })
      }

      "disconnect" -> {
        GoEasy.disconnect(object : GoEasyEventListener() {
          override fun onSuccess(data: GResult<*>) {
            Log.i(TAG, "kt: disconnect onSuccess")
            emitEvent("disconnect.onSuccess", resultToMap(data))
          }
          override fun onFailed(error: GResult<*>) {
            Log.i(TAG, "kt: Failed to disconnect GoEasy, code: ${error.code}, error: ${error.data}")
            emitEvent("disconnect.onFailed", resultToMap(error))
          }
        })
      }

      "subscribe" -> {
        val channel = call.argument<String>("channel") as String
        val presence = call.argument<Map<String,Boolean>>("presence") as Map<String, Any>
        Log.i(TAG, "kt: subscribe -- ${channel} ${presence}")
        val subscribeOptions = SubscribeOptions(
          channel = channel,
          presence = presence,
          onMessage = { message:PubSubMessage ->
            Log.i(TAG, "kt: onMessage---$message")
            val map = HashMap<String, Any>()
            map.put("channel", message.channel)
            map.put("content", message.content)
            map.put("time", message.time)
            Log.i(TAG, "kt: onMessage---map: $map")
            emitEvent("subscribe.onMessage", map)
          },
          onSuccess = {
            Log.i(TAG, "kt: subscribe onSuccess")
            emitEvent("subscribe.onSuccess",HashMap<String, Any>())
          },
          onFailed = { error:GResult<*> ->
            Log.i(TAG, "kt: subscribe onFailed, code: ${error.code}, error: ${error.data}")
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
            Log.i(TAG, "kt: unsubscribe onSuccess")
            emitEvent("unsubscribe.onSuccess",HashMap<String, Any>())
          },
          onFailed = { error:GResult<*> ->
            Log.i(TAG, "kt: unsubscribe onFailed, code: ${error.code}, error: ${error.data}")
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
            Log.i(TAG, "kt: onPresence $event")
            val memberMap = convertMemberToMap(event.member)
            Log.i(TAG, "kt: memberMap ${memberMap}")

            val membersListMap = event.members.map { member ->
              Log.i(TAG, "kt: onPresence member: $member")
              convertMemberToMap(member)
            }

            val map = HashMap<String, Any>()
            map.put("channel", channel)
            map.put("action", event.action)
            map.put("amount", event.amount)
            map.put("member",memberMap)
            map.put("members", membersListMap)
            Log.i(TAG, "kt: onPresence map: $map")
            emitEvent("subscribePresence.onPresence",map)
          },
          onSuccess = {
            Log.i(TAG, "kt: subscribePresence onSuccess")
            emitEvent("subscribePresence.onSuccess",HashMap<String, Any>())
          },
          onFailed = { error:GResult<*> ->
            Log.e(TAG, "kt: subscribePresence onFailed, code: ${error.code}, error: ${error.data}")
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
            Log.i(TAG, "kt: unSubscribePresence onSuccess")
            emitEvent("unSubscribePresence.onSuccess",HashMap<String, Any>())
          },
          onFailed = { error:GResult<*> ->
            Log.e(TAG, "kt: unSubscribePresence onFailed, code: ${error.code}, error: ${error.data}")
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
            Log.i(TAG, "kt: hereNow onSuccess $data")
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

            Log.i(TAG, "kt: hereNow onSuccess map: $map")
            emitEvent("hereNow.onSuccess",map)
          },
          onFailed = { error:GResult<*> ->
            Log.e(TAG, "kt: hereNow onFailed, code: ${error.code}, error: ${error.data}")
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
            Log.i(TAG, "kt: history onSuccess $data")
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
            Log.i(TAG, "kt: history onSuccess, map: ${map}")

            emitEvent("history.onSuccess",map)
          },
          onFailed = { error:GResult<*> ->
            Log.e(TAG, "kt: history onFailed, code: ${error.code}, error: ${error.data}")
            emitEvent("history.onFailed", resultToMap(error))
          }
        )
        GPubSub.history(options)
      }

      "publish" -> {
        val channel = call.argument<String>("channel") as String
        val message = call.argument<String>("message") as String
        val qos = call.argument<String>("qos") as Int?
        Log.i(TAG, "kt: publish -- channel-${channel} message-${message} qos-${qos}")
        val options = PublishOptions(channel,message,qos)
        GPubSub.publish(options, object : GoEasyEventListener() {
          override fun onSuccess(data: GResult<*>) {
            Log.e(TAG, "kt: publish onSuccess, code: ${data.code}, error: ${data.data}")
            emitEvent("publish.onSuccess", resultToMap(data))
          }
          override fun onFailed(error: GResult<*>) {
            Log.e(TAG, "kt: publish onFailed, code: ${error.code}, error: ${error.data}")
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
