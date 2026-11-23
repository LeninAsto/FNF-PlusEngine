package ::APP_PACKAGE::

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ErrorOutline
import androidx.compose.material.icons.automirrored.rounded.Send
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import org.haxe.extension.Extension
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.system.exitProcess

object EngineAndroidBridge {
	private const val TAG = "EngineAndroidBridge"
	private const val CRASH_FILE = "plus_engine_last_crash.txt"
	private const val MAX_REPORT_CHARS = 60000
	private const val PREFS_NAME = "plus_engine_launcher"
	private const val PREF_SHOW_LAUNCHER = "show_launcher"
	private const val PREF_AUTO_START = "auto_start"
	const val EXTRA_CRASH_FILE = "plus.engine.extra.CRASH_FILE"
	private val crashActivityStarted = AtomicBoolean(false)

	@JvmStatic
	fun setLauncherPrefs(showLauncher: Boolean, autoStart: Boolean) {
		val context = Extension.mainContext ?: return
		context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
			.edit()
			.putBoolean(PREF_SHOW_LAUNCHER, showLauncher)
			.putBoolean(PREF_AUTO_START, autoStart)
			.commit()
	}

	@JvmStatic
	fun getLauncherPrefs(): String {
		val context = Extension.mainContext ?: return ""
		val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
		return "${if (prefs.getBoolean(PREF_SHOW_LAUNCHER, true)) 1 else 0}|${if (prefs.getBoolean(PREF_AUTO_START, false)) 1 else 0}"
	}

	@JvmStatic
	fun showAlert(title: String?, message: String?): Boolean {
		val activity = Extension.mainActivity ?: return false
		if (activity.isFinishing || (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1 && activity.isDestroyed)) return false

		return runCatching {
			activity.runOnUiThread {
				runCatching {
					AlertDialog.Builder(activity)
						.setTitle(title.orEmpty())
						.setMessage(message.orEmpty())
						.setPositiveButton(android.R.string.ok, null)
						.setCancelable(true)
						.show()
				}.onFailure {
					Log.e(TAG, "Alert dialog could not be shown.", it)
					Toast.makeText(activity.applicationContext, message.orEmpty(), Toast.LENGTH_LONG).show()
				}
			}
			true
		}.getOrElse {
			Log.e(TAG, "Alert dialog could not be dispatched.", it)
			false
		}
	}

	@JvmStatic
	fun showHaxeCrash(title: String?, report: String?): Boolean {
		val context = Extension.mainContext ?: Extension.mainActivity ?: return false
		if (!crashActivityStarted.compareAndSet(false, true)) return true
		val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS Z", Locale.US).format(Date())
		val formattedReport = buildString {
			appendLine("Time: $timestamp")
			appendLine("Package: ${context.packageName}")
			appendLine("Source: Plus Engine Haxe crash handler")
			if (!title.isNullOrBlank()) appendLine("Title: $title")
			appendLine()
			appendLine(report ?: "No Haxe crash report was provided.")
		}

		return runCatching {
			launchCrashActivity(context, formattedReport)
			scheduleGameProcessExit()
			true
		}.onFailure {
			crashActivityStarted.set(false)
			Log.e(TAG, "Engine crash activity could not be launched.", it)
		}.getOrDefault(false)
	}

	private fun scheduleGameProcessExit() {
		val gamePid = Process.myPid()
		Thread({
			try {
				// startActivity is asynchronous. Give the recovery process enough time
				// to create its window before terminating the broken game process.
				Thread.sleep(1200)
			} catch (_: InterruptedException) {
			}
			Process.killProcess(gamePid)
		}, "PlusEngine-crash-exit").apply {
			isDaemon = false
			start()
		}
	}

	private fun launchCrashActivity(context: Context, report: String) {
		val crashFile = File(context.cacheDir, CRASH_FILE)
		crashFile.writeText(report.take(MAX_REPORT_CHARS))

		val intent = Intent(context, EngineCrashActivity::class.java)
			.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
			.putExtra(EXTRA_CRASH_FILE, crashFile.absolutePath)

		context.startActivity(intent)
	}

	@Suppress("DEPRECATION")
	fun PackageInfo.compatLongVersionCode(): Long {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) longVersionCode else versionCode.toLong()
	}
}

class EngineCrashActivity : ComponentActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		val report = readCrashReport().ifBlank { getString(R.string.plus_crash_empty) }
		setContent {
			EngineCrashTheme {
				CrashRecoveryScreen(report, ::restartGame, ::shareCrashReport, ::closeRecovery)
			}
		}
	}

	private fun readCrashReport(): String {
		val path = intent.getStringExtra(EngineAndroidBridge.EXTRA_CRASH_FILE) ?: return ""
		return runCatching { File(path).readText() }.getOrDefault("")
	}

	private fun restartGame() {
		packageManager.getLaunchIntentForPackage(packageName)?.let {
			it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
			startActivity(it)
		}
		closeRecovery()
	}

	private fun closeRecovery() {
		finishAndRemoveTask()
		Process.killProcess(Process.myPid())
		exitProcess(0)
	}

	private fun shareCrashReport() {
		val intent = Intent(Intent.ACTION_SEND).apply {
			type = "text/plain"
			putExtra(Intent.EXTRA_SUBJECT, getString(R.string.plus_crash_share_subject))
			putExtra(Intent.EXTRA_TEXT, readCrashReport())
		}
		startActivity(Intent.createChooser(intent, getString(R.string.plus_crash_send_logs)))
	}
}

@Composable
private fun EngineCrashTheme(content: @Composable () -> Unit) {
	val context = LocalContext.current
	val dark = isSystemInDarkTheme()
	val colors: ColorScheme = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
		if (dark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
	} else {
		if (dark) darkColorScheme(
			primary = Color(0xFFFFB15C), onPrimary = Color(0xFF301600), secondary = Color(0xFF8AD7C1),
			background = Color(0xFF101113), surface = Color(0xFF191B20), surfaceVariant = Color(0xFF22252C),
			onBackground = Color(0xFFF2F0EA), onSurface = Color(0xFFF2F0EA), onSurfaceVariant = Color(0xFFC9CDD6)
		) else lightColorScheme()
	}
	MaterialTheme(colorScheme = colors, content = content)
}

@Composable
private fun CrashRecoveryScreen(report: String, onRestart: () -> Unit, onSendLogs: () -> Unit, onClose: () -> Unit) {
	var showDetails by remember { mutableStateOf(false) }
	var showRecentLogs by remember { mutableStateOf(false) }
	val context = LocalContext.current
	val recentLogs = remember(report) { extractRecentLogs(report) }
	Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
		Box(
			modifier = Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(MaterialTheme.colorScheme.primary.copy(alpha = 0.18f), MaterialTheme.colorScheme.background))).padding(24.dp),
			contentAlignment = Alignment.Center
		) {
			Card(
				modifier = Modifier.fillMaxWidth().heightIn(max = 680.dp), shape = RoundedCornerShape(28.dp),
				colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
			) {
				Column(modifier = Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
					Row(verticalAlignment = Alignment.CenterVertically) {
						Box(modifier = Modifier.size(56.dp).clip(CircleShape).background(MaterialTheme.colorScheme.error.copy(alpha = 0.18f)), contentAlignment = Alignment.Center) {
							Icon(Icons.Rounded.ErrorOutline, null, modifier = Modifier.size(30.dp), tint = MaterialTheme.colorScheme.error)
						}
						Spacer(Modifier.width(16.dp))
						Column {
							Text(context.getString(R.string.plus_crash_title), style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
							Text(context.getString(R.string.plus_crash_subtitle), color = MaterialTheme.colorScheme.onSurfaceVariant)
						}
					}
					Button(onClick = onRestart, modifier = Modifier.fillMaxWidth()) { Text(context.getString(R.string.plus_crash_restart)) }
					OutlinedButton(onClick = onSendLogs, modifier = Modifier.fillMaxWidth()) {
						Icon(Icons.AutoMirrored.Rounded.Send, null, modifier = Modifier.size(18.dp))
						Spacer(Modifier.width(8.dp))
						Text(context.getString(R.string.plus_crash_send_logs))
					}
					OutlinedButton(onClick = { showDetails = !showDetails }, modifier = Modifier.fillMaxWidth()) {
						Text(context.getString(if (showDetails) R.string.plus_crash_hide_details else R.string.plus_crash_show_details))
					}
					OutlinedButton(onClick = { showRecentLogs = !showRecentLogs }, modifier = Modifier.fillMaxWidth()) {
						Text(context.getString(if (showRecentLogs) R.string.plus_crash_hide_recent_logs else R.string.plus_crash_show_recent_logs))
					}
					if (showRecentLogs) {
						SelectionContainer {
							Text(recentLogs, modifier = Modifier.fillMaxWidth().heightIn(min = 120.dp, max = 360.dp).verticalScroll(rememberScrollState()).background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(14.dp)).padding(14.dp), fontFamily = FontFamily.Monospace, style = MaterialTheme.typography.bodySmall)
						}
					}
					if (showDetails) {
						SelectionContainer {
							Text(report, modifier = Modifier.fillMaxWidth().heightIn(min = 120.dp, max = 360.dp).verticalScroll(rememberScrollState()).background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(14.dp)).padding(14.dp), fontFamily = FontFamily.Monospace, style = MaterialTheme.typography.bodySmall)
						}
					}
					OutlinedButton(onClick = onClose, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error)) { Text(context.getString(R.string.plus_crash_close)) }
				}
			}
		}
	}
}

private fun extractRecentLogs(report: String): String {
	val marker = "Recent trace lines before crash"
	val start = report.indexOf(marker)
	if (start < 0) return "No recent trace lines were captured before this crash."
	return report.substring(start).removeSuffix("\n========================")
}
