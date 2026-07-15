package com.kasir.kasir_app

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "kasir_app/file_saver"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDocuments" -> {
                    val name = call.argument<String>("name") ?: ""
                    val bytes = call.argument<ByteArray>("bytes") ?: ByteArray(0)
                    val mime = call.argument<String>("mimeType") ?: "application/octet-stream"
                    try {
                        val path = saveToDocuments(name, bytes, mime)
                        result.success(path)
                    } catch (e: Exception) {
                        result.error("SAVE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Simpan file ke folder Documents publik. Return path absolut (Android <10) atau content uri (Android 10+). */
    private fun saveToDocuments(name: String, bytes: ByteArray, mime: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Documents/")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val collection = MediaStore.Files.getContentUri("external")
            val uri = resolver.insert(collection, values)
                ?: throw RuntimeException("MediaStore insert gagal")
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw RuntimeException("Tidak bisa membuka output stream")
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        } else {
            @Suppress("DEPRECATION")
            val docsDir = File(Environment.getExternalStorageDirectory(), "Documents")
            if (!docsDir.exists()) docsDir.mkdirs()
            val file = File(docsDir, name)
            file.writeBytes(bytes)
            return file.absolutePath
        }
    }
}
