package com.personalfitnessos.personal_fitness_os

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.personalfitnessos.liftr/app_updater"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppVersion" -> handleGetAppVersion(result)
                    "getUpdatesCacheDir" -> handleGetUpdatesCacheDir(result)
                    "canRequestPackageInstalls" -> handleCanRequestPackageInstalls(result)
                    "openInstallPermissionSettings" -> handleOpenInstallPermissionSettings(result)
                    "installApk" -> handleInstallApk(call.argument<String>("filePath"), result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleGetAppVersion(result: MethodChannel.Result) {
        try {
            val info: PackageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }
            val versionCode: Long = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                info.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                info.versionCode.toLong()
            }
            result.success(
                mapOf(
                    "versionName" to (info.versionName ?: "0.0.0"),
                    "buildNumber" to versionCode.toInt(),
                ),
            )
        } catch (e: Exception) {
            result.error("VERSION_ERROR", e.message, null)
        }
    }

    private fun handleGetUpdatesCacheDir(result: MethodChannel.Result) {
        try {
            val dir = File(cacheDir, "updates").apply { mkdirs() }
            result.success(dir.absolutePath)
        } catch (e: Exception) {
            result.error("CACHE_DIR_ERROR", e.message, null)
        }
    }

    private fun handleCanRequestPackageInstalls(result: MethodChannel.Result) {
        val allowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
        result.success(allowed)
    }

    private fun handleOpenInstallPermissionSettings(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName"),
                ).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", e.message, null)
        }
    }

    private fun handleInstallApk(filePath: String?, result: MethodChannel.Result) {
        if (filePath.isNullOrBlank()) {
            result.error("INVALID_ARGS", "Missing filePath", null)
            return
        }
        try {
            val updatesDir = File(cacheDir, "updates").canonicalFile
            val apkFile = File(filePath).canonicalFile
            if (!apkFile.exists() || !apkFile.path.startsWith(updatesDir.path + File.separator)) {
                result.error("INVALID_FILE", "APK file not found in updates cache directory", null)
                return
            }
            val contentUri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                apkFile,
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(contentUri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_ERROR", e.message, null)
        }
    }
}
