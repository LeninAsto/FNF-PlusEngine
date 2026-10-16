package ::APP_PACKAGE::

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.util.Log
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import org.haxe.extension.Extension
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.system.exitProcess

object EngineAndroidBridge {
	private const val TAG = "EngineAndroidBridge"
	private const val CRASH_FILE = "plus_engine_last_crash.txt"
	private const val MAX_REPORT_CHARS = 60000
	private const val PREFS_NAME = "plus_engine_launcher"
	private const val PREF_SHOW_LAUNCHER = "show_launcher"
	private const val PREF_AUTO_START = "auto_start"
	const val EXTRA_CRASH_FILE = "plus.engine.extra.CRASH_FILE"

	@JvmStatic
	fun setLauncherPrefs(showLauncher: Boolean, autoStart: Boolean) {
		val context = Extension.mainContext ?: return
		context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
			.edit()
			.putBoolean(PREF_SHOW_LAUNCHER, showLauncher)
			.putBoolean(PREF_AUTO_START, autoStart)
			.apply()
	}

	@JvmStatic
	fun showHaxeCrash(title: String?, report: String?) {
		val context = Extension.mainContext ?: Extension.mainActivity ?: return
		val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS Z", Locale.US).format(Date())
		val formattedReport = buildString {
			appendLine("Time: $timestamp")
			appendLine("Package: ${context.packageName}")
			appendLine("Source: Plus Engine Haxe crash handler")
			if (!title.isNullOrBlank()) appendLine("Title: $title")
			appendLine()
			appendLine(report ?: "No Haxe crash report was provided.")
		}

		runCatching {
			launchCrashActivity(context, formattedReport)
		}.onFailure {
			Log.e(TAG, "Engine crash activity could not be launched.", it)
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

class EngineCrashActivity : Activity() {
	private var reportVisible = false
	private lateinit var details: TextView
	private lateinit var toggle: Button

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		val report = readCrashReport().ifBlank { getString(R.string.plus_crash_empty) }

		val root = LinearLayout(this).apply {
			orientation = LinearLayout.VERTICAL
			setPadding(dp(22), dp(22), dp(22), dp(22))
			setBackgroundColor(0xFF101113.toInt())
		}

		root.addView(TextView(this).apply {
			text = getString(R.string.plus_crash_title)
			textSize = 24f
			setTextColor(0xFFFFF3E8.toInt())
			setTypeface(typeface, android.graphics.Typeface.BOLD)
		})

		root.addView(TextView(this).apply {
			text = getString(R.string.plus_crash_subtitle)
			textSize = 15f
			setTextColor(0xFFC9CDD6.toInt())
			setPadding(0, dp(8), 0, dp(18))
		})

		val actions = LinearLayout(this).apply {
			orientation = LinearLayout.HORIZONTAL
			gravity = Gravity.CENTER
		}
		actions.addView(Button(this).apply {
			text = getString(R.string.plus_crash_restart)
			setOnClickListener { restartGame() }
		}, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply { marginEnd = dp(8) })
		actions.addView(Button(this).apply {
			text = getString(R.string.plus_crash_close)
			setOnClickListener { closeRecovery() }
		}, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply { marginStart = dp(8) })
		root.addView(actions)

		toggle = Button(this).apply {
			text = getString(R.string.plus_crash_show_details)
			setOnClickListener { toggleReport() }
		}
		root.addView(toggle, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
			topMargin = dp(14)
		})

		details = TextView(this).apply {
			text = report
			textSize = 12f
			typeface = android.graphics.Typeface.MONOSPACE
			setTextColor(0xFFE6E1E5.toInt())
			setPadding(dp(12), dp(12), dp(12), dp(12))
			visibility = View.GONE
		}
		root.addView(ScrollView(this).apply {
			setBackgroundColor(0xFF22252C.toInt())
			addView(details)
			visibility = View.GONE
			tag = "details_scroll"
		}, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f).apply {
			topMargin = dp(12)
		})

		setContentView(root)
	}

	private fun toggleReport() {
		reportVisible = !reportVisible
		val scroll = details.parent as View
		scroll.visibility = if (reportVisible) View.VISIBLE else View.GONE
		details.visibility = if (reportVisible) View.VISIBLE else View.GONE
		toggle.text = getString(if (reportVisible) R.string.plus_crash_hide_details else R.string.plus_crash_show_details)
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

	private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
