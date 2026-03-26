package com.example.oklifor_dating_app

import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import android.os.Environment
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import java.io.File

/// [FlutterFragmentActivity] requis pour la biométrie ([local_auth]).
class MainActivity : FlutterFragmentActivity() {
  private val channelName = "oklifor.media/save_to_gallery"
  private val downloadsChannelName = "oklifor.media/save_to_downloads"
  private val storageChannelName = "oklifor.media/storage"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "saveFile" -> {
            val path = call.argument<String>("path") ?: ""
            val isVideo = call.argument<Boolean>("isVideo") ?: false
            val suggestedName = call.argument<String>("suggestedName") ?: ""
            if (path.isBlank()) {
              result.success(false)
              return@setMethodCallHandler
            }
            try {
              val ok = saveToGallery(path, isVideo, suggestedName)
              result.success(ok)
            } catch (e: Exception) {
              result.success(false)
            }
          }
          else -> result.notImplemented()
        }
      }

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "saveFile" -> {
            val path = call.argument<String>("path") ?: ""
            val suggestedName = call.argument<String>("suggestedName") ?: ""
            val mimeType = call.argument<String>("mimeType") ?: ""
            if (path.isBlank()) {
              result.success(false)
              return@setMethodCallHandler
            }
            try {
              val ok = saveToDownloads(path, suggestedName, mimeType)
              result.success(ok)
            } catch (e: Exception) {
              result.success(false)
            }
          }
          else -> result.notImplemented()
        }
      }

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, storageChannelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "getExternalMediaBasePath" -> {
            try {
              // Preferred: /storage/emulated/0/Android/media/<package>/
              val dirs = this.externalMediaDirs
              val base = if (dirs != null && dirs.isNotEmpty() && dirs[0] != null) {
                dirs[0]
              } else {
                // Fallback: /storage/emulated/0/Android/media/<package>/
                File(Environment.getExternalStorageDirectory(), "Android/media/" + applicationContext.packageName)
              }
              if (!base.exists()) {
                base.mkdirs()
              }
              result.success(base.absolutePath)
            } catch (e: Exception) {
              result.success(null)
            }
          }
          else -> result.notImplemented()
        }
      }
  }

  private fun saveToGallery(path: String, isVideo: Boolean, suggestedName: String): Boolean {
    val resolver = applicationContext.contentResolver
    val now = System.currentTimeMillis()
    val baseName = suggestedName.takeIf { it.isNotBlank() } ?: (if (isVideo) "video_$now" else "image_$now")
    val fileName = if (baseName.contains(".")) baseName else baseName + (if (isVideo) ".mp4" else ".jpg")
    val mime = if (isVideo) "video/mp4" else "image/jpeg"

    val collection = if (isVideo) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
      else MediaStore.Video.Media.EXTERNAL_CONTENT_URI
    } else {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
      else MediaStore.Images.Media.EXTERNAL_CONTENT_URI
    }

    val values = ContentValues().apply {
      put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
      put(MediaStore.MediaColumns.MIME_TYPE, mime)
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        put(MediaStore.MediaColumns.IS_PENDING, 1)
        put(MediaStore.MediaColumns.RELATIVE_PATH, if (isVideo) "Movies/Oklifor" else "Pictures/Oklifor")
      }
    }

    val uri = resolver.insert(collection, values) ?: return false
    resolver.openOutputStream(uri)?.use { out ->
      java.io.File(path).inputStream().use { input ->
        input.copyTo(out)
      }
    } ?: return false

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      values.clear()
      values.put(MediaStore.MediaColumns.IS_PENDING, 0)
      resolver.update(uri, values, null, null)
    }
    return true
  }

  private fun saveToDownloads(path: String, suggestedName: String, mimeType: String): Boolean {
    val resolver = applicationContext.contentResolver
    val now = System.currentTimeMillis()
    val baseName = suggestedName.takeIf { it.isNotBlank() } ?: "fichier_$now"
    val fileName = baseName
    val mime = mimeType.takeIf { it.isNotBlank() } ?: "application/octet-stream"

    val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
    } else {
      MediaStore.Downloads.EXTERNAL_CONTENT_URI
    }

    val values = ContentValues().apply {
      put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
      put(MediaStore.MediaColumns.MIME_TYPE, mime)
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        put(MediaStore.MediaColumns.IS_PENDING, 1)
        put(MediaStore.MediaColumns.RELATIVE_PATH, "Download/Oklifor")
      }
    }

    val uri = resolver.insert(collection, values) ?: return false
    resolver.openOutputStream(uri)?.use { out ->
      java.io.File(path).inputStream().use { input ->
        input.copyTo(out)
      }
    } ?: return false

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      values.clear()
      values.put(MediaStore.MediaColumns.IS_PENDING, 0)
      resolver.update(uri, values, null, null)
    }
    return true
  }
}
