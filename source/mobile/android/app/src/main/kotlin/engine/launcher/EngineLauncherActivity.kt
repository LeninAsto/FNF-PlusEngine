package ::APP_PACKAGE::.launcher

import android.Manifest
import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.Settings
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.Launch
import androidx.compose.material.icons.rounded.Download
import androidx.compose.material.icons.rounded.FolderOpen
import androidx.compose.material.icons.rounded.Language
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Security
import androidx.compose.material.icons.rounded.Storage
import androidx.compose.material.icons.rounded.SystemUpdate
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.core.os.LocaleListCompat
import ::APP_PACKAGE::.BuildConfig
import ::APP_PACKAGE::.MainActivity
import ::APP_PACKAGE::.R
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread
import org.json.JSONObject

class EngineLauncherActivity : ComponentActivity() {
	private companion object {
		private const val DOCUMENTS_UI_BROWSE_ACTION = "android.provider.action.BROWSE"
		private const val EXTERNAL_STORAGE_AUTHORITY = "com.android.externalstorage.documents"
		private const val FORCE_LANDSCAPE_EXTRA = "org.haxe.lime.forceLandscapeBeforeSdl"
		private const val PREFS_NAME = "plus_engine_launcher"
		private const val PREF_SHOW_LAUNCHER = "show_launcher"
		private const val PREF_AUTO_START = "auto_start"
		private const val PRIMARY_ROOT_ID = "primary"
		private val DOCUMENTS_UI_PACKAGES = listOf(null, "com.google.android.documentsui", "com.android.documentsui")
	}

	private val modInstallerPackages = listOf(
		"com.leninasto.fnfmodinstaler",
		"com.leninasto.fnfmodinstaller"
	)

	private var permissions by mutableStateOf(emptyList<PermissionItem>())
	private var storageRows by mutableStateOf(emptyList<StorageItem>())
	private var updateState by mutableStateOf(UpdateState())
	private var modInstallerInstalled by mutableStateOf(false)
	private var showLauncher by mutableStateOf(true)
	private var autoStart by mutableStateOf(false)
	private var gameLaunchPending = false
	private var autoStartPosted = false

	private val runtimePermissionLauncher = registerForActivityResult(
		ActivityResultContracts.RequestMultiplePermissions()
	) {
		refreshState()
	}

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		refreshLauncherPrefs()
		refreshState()

		if (!showLauncher) {
			startGame()
			return
		}

		setContent {
			LauncherTheme {
				LauncherScreen(
					permissions = permissions,
					storageRows = storageRows,
					updateState = updateState,
					modInstallerInstalled = modInstallerInstalled,
					showLauncher = showLauncher,
					autoStart = autoStart,
					onStartGame = ::startGame,
					onShowLauncherChange = ::updateShowLauncher,
					onAutoStartChange = ::updateAutoStart,
					onOpenData = { openFolderInFiles(getGameDataDirectory()) },
					onOpenExternal = { openFolderInFiles(getPublicEngineDirectory()) },
					onRequestPermissions = ::requestMissingPermissions,
					onOpenSettings = ::openBestPermissionSettings,
					onCheckUpdates = ::checkForUpdates,
					onDownloadUpdate = ::downloadUpdate,
					onRefreshStorage = ::refreshStorage,
					onOpenModInstaller = ::openModInstaller,
					onOpenGithub = ::openGithub,
					onSetLanguage = ::setLanguage
				)
			}
		}

		queueAutoStartIfNeeded()
	}

	override fun onResume() {
		super.onResume()
		requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_FULL_USER
		gameLaunchPending = false
		refreshState()
	}

	private fun refreshState() {
		permissions = buildPermissionItems()
		modInstallerInstalled = findModInstallerPackage() != null
		refreshStorage()
	}

	private fun refreshLauncherPrefs() {
		val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
		showLauncher = prefs.getBoolean(PREF_SHOW_LAUNCHER, true)
		autoStart = prefs.getBoolean(PREF_AUTO_START, false)
	}

	private fun updateShowLauncher(enabled: Boolean) {
		showLauncher = enabled
		getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
			.edit()
			.putBoolean(PREF_SHOW_LAUNCHER, enabled)
			.apply()
	}

	private fun updateAutoStart(enabled: Boolean) {
		autoStart = enabled
		getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
			.edit()
			.putBoolean(PREF_AUTO_START, enabled)
			.apply()
		if (enabled) queueAutoStartIfNeeded()
	}

	private fun queueAutoStartIfNeeded() {
		if (!autoStart || autoStartPosted || gameLaunchPending) return
		autoStartPosted = true
		window.decorView.postDelayed({
			if (autoStart && !gameLaunchPending) startGame()
		}, 3000L)
	}

	private fun startGame() {
		if (gameLaunchPending) return

		gameLaunchPending = true
		requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE

		val launchDelay = if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) 80L else 360L
		window.decorView.postDelayed({
			val intent = Intent(this, MainActivity::class.java)
				.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
				.putExtra(FORCE_LANDSCAPE_EXTRA, true)

			runCatching {
				startActivity(intent)
			}.onFailure {
				gameLaunchPending = false
				requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_FULL_USER
				Toast.makeText(this, it.localizedMessage ?: it.toString(), Toast.LENGTH_LONG).show()
			}
		}, launchDelay)
	}

	private fun getGameDataDirectory(): File {
		val scoped = getExternalFilesDir(null)
		return scoped ?: File(getSharedStorageRoot(), "Android/data/$packageName/files")
	}

	private fun getPublicEngineDirectory(): File {
		return File(getSharedStorageRoot(), ".PlusEngine")
	}

	private fun openFolderInFiles(folder: File) {
		folder.mkdirs()

		val target = getDocumentsUiFolderTarget(folder)
		if (target == null) {
			Toast.makeText(this, folder.absolutePath, Toast.LENGTH_LONG).show()
			return
		}

		for (intent in buildFolderBrowseIntents(target)) {
			runCatching {
				startActivity(intent)
			}.onSuccess {
				return
			}
		}

		Toast.makeText(this, folder.absolutePath, Toast.LENGTH_LONG).show()
	}

	private fun getDocumentsUiFolderTarget(folder: File): FolderTarget? {
		val root = getSharedStorageRoot().absolutePath.replace('\\', '/').trimEnd('/')
		val path = folder.absolutePath.replace('\\', '/')
		if (!path.startsWith(root)) return null

		val relative = path.removePrefix(root).trimStart('/')
		if (relative.isBlank()) return null

		val documentId = "$PRIMARY_ROOT_ID:$relative"
		return FolderTarget(
			documentUri = DocumentsContract.buildDocumentUri(EXTERNAL_STORAGE_AUTHORITY, documentId),
			rootUri = DocumentsContract.buildRootUri(EXTERNAL_STORAGE_AUTHORITY, PRIMARY_ROOT_ID)
		)
	}

	private fun buildFolderBrowseIntents(target: FolderTarget): List<Intent> {
		val baseIntents = listOf(
			Intent(DOCUMENTS_UI_BROWSE_ACTION)
				.setData(target.documentUri),
			Intent(Intent.ACTION_VIEW)
				.setDataAndType(target.documentUri, DocumentsContract.Document.MIME_TYPE_DIR),
			Intent(Intent.ACTION_VIEW)
				.setDataAndType(target.rootUri, DocumentsContract.Root.MIME_TYPE_ITEM)
				.putExtra(DocumentsContract.EXTRA_INITIAL_URI, target.documentUri)
		)

		return baseIntents.flatMap { base ->
			DOCUMENTS_UI_PACKAGES.map { packageName ->
				Intent(base)
					.addCategory(Intent.CATEGORY_DEFAULT)
					.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
					.putExtra("android.provider.extra.SHOW_ADVANCED", true)
					.apply {
						if (packageName != null) setPackage(packageName)
					}
			}
		}
	}

	@Suppress("DEPRECATION")
	private fun getSharedStorageRoot(): File {
		return Environment.getExternalStorageDirectory()
	}

	private fun buildPermissionItems(): List<PermissionItem> {
		val items = mutableListOf<PermissionItem>()
		items += PermissionItem(
			name = "Internet",
			status = PermissionStatus.NOT_NEEDED,
			description = "Network checks and downloads"
		)
		items += PermissionItem(
			name = "Network state",
			status = PermissionStatus.NOT_NEEDED,
			description = "Detect connection state"
		)

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
			items += PermissionItem(
				name = "All files access",
				status = if (Environment.isExternalStorageManager()) PermissionStatus.GRANTED else PermissionStatus.REQUIRED,
				description = "/external mods and shared files"
			)
		} else {
			items += PermissionItem(
				name = "External storage",
				status = if (hasPermission(Manifest.permission.READ_EXTERNAL_STORAGE)) PermissionStatus.GRANTED else PermissionStatus.REQUIRED,
				description = "Legacy mods and shared files"
			)
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
			items += PermissionItem(
				name = "Media images",
				status = if (hasPermission(Manifest.permission.READ_MEDIA_IMAGES)) PermissionStatus.GRANTED else PermissionStatus.REQUIRED,
				description = "Image imports"
			)
			items += PermissionItem(
				name = "Media audio",
				status = if (hasPermission(Manifest.permission.READ_MEDIA_AUDIO)) PermissionStatus.GRANTED else PermissionStatus.REQUIRED,
				description = "Audio imports"
			)
			items += PermissionItem(
				name = "Media video",
				status = if (hasPermission(Manifest.permission.READ_MEDIA_VIDEO)) PermissionStatus.GRANTED else PermissionStatus.REQUIRED,
				description = "Video imports"
			)
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
			items += PermissionItem(
				name = "Selected visual media",
				status = if (hasPermission("android.permission.READ_MEDIA_VISUAL_USER_SELECTED")) PermissionStatus.GRANTED else PermissionStatus.REQUIRED,
				description = "Android 14 partial gallery access"
			)
		}

		return items
	}

	private fun hasPermission(permission: String): Boolean {
		return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
	}

	private fun requestMissingPermissions() {
		val runtimePermissions = mutableListOf<String>()

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
			runtimePermissions += Manifest.permission.READ_MEDIA_IMAGES
			runtimePermissions += Manifest.permission.READ_MEDIA_AUDIO
			runtimePermissions += Manifest.permission.READ_MEDIA_VIDEO
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
				runtimePermissions += "android.permission.READ_MEDIA_VISUAL_USER_SELECTED"
			}
		} else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			runtimePermissions += Manifest.permission.READ_EXTERNAL_STORAGE
			runtimePermissions += Manifest.permission.WRITE_EXTERNAL_STORAGE
		}

		val missing = runtimePermissions.filterNot(::hasPermission).toTypedArray()
		if (missing.isNotEmpty()) {
			runtimePermissionLauncher.launch(missing)
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && !Environment.isExternalStorageManager()) {
			openAllFilesSettings()
		}
	}

	private fun openBestPermissionSettings() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && !Environment.isExternalStorageManager()) {
			openAllFilesSettings()
		} else {
			openAppSettings()
		}
	}

	private fun openAllFilesSettings() {
		val uri = Uri.parse("package:$packageName")
		val intents = listOf(
			Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).setData(uri),
			Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION),
			Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).setData(uri)
		)

		for (intent in intents) {
			if (runCatching { startActivity(intent); true }.getOrDefault(false)) return
		}
	}

	private fun openAppSettings() {
		startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).setData(Uri.parse("package:$packageName")))
	}

	private fun refreshStorage() {
		storageRows = listOf(StorageItem(getString(R.string.plus_launcher_ready), "..."))
		thread(name = "PlusStorageScan") {
			val rows = listOf(
				StorageItem(getString(R.string.plus_launcher_app_data), formatBytes(sizeOf(filesDir.parentFile))),
				StorageItem(getString(R.string.plus_launcher_game_data), formatBytes(sizeOf(getGameDataDirectory()))),
				StorageItem(getString(R.string.plus_launcher_mods), formatBytes(sizeOf(File(getGameDataDirectory(), "mods")) + sizeOf(File(getPublicEngineDirectory(), "mods")))),
				StorageItem(getString(R.string.plus_launcher_apk), formatBytes(File(applicationInfo.sourceDir).length()))
			)
			runOnUiThread { storageRows = rows }
		}
	}

	private fun sizeOf(file: File?): Long {
		if (file == null || !file.exists()) return 0L
		if (file.isFile) return file.length()

		var total = 0L
		file.listFiles()?.forEach { child ->
			total += sizeOf(child)
		}
		return total
	}

	private fun formatBytes(bytes: Long): String {
		if (bytes < 1024L) return "$bytes B"
		val units = arrayOf("KB", "MB", "GB", "TB")
		var value = bytes / 1024.0
		var unit = 0
		while (value >= 1024.0 && unit < units.lastIndex) {
			value /= 1024.0
			unit++
		}
		return String.format("%.1f %s", value, units[unit])
	}

	private fun checkForUpdates() {
		updateState = updateState.copy(status = getString(R.string.plus_launcher_checking), checking = true)
		thread(name = "PlusUpdateCheck") {
			val result = runCatching {
				val remoteVersion = readText("https://raw.githubusercontent.com/Psych-Plus-Team/FNF-PlusEngine/refs/heads/main/gitVersion.txt")
					.lineSequence()
					.firstOrNull()
					.orEmpty()
					.trim()
				val releaseUrl = findLatestApkUrl()
				val hasUpdate = compareVersions(BuildConfig.VERSION_NAME, remoteVersion) < 0
				UpdateState(
					currentVersion = BuildConfig.VERSION_NAME,
					latestVersion = remoteVersion.ifBlank { BuildConfig.VERSION_NAME },
					status = if (hasUpdate) getString(R.string.plus_launcher_update_available) else getString(R.string.plus_launcher_no_update),
					downloadUrl = releaseUrl,
					checking = false,
					hasUpdate = hasUpdate
				)
			}.getOrElse {
				UpdateState(
					currentVersion = BuildConfig.VERSION_NAME,
					status = getString(R.string.plus_launcher_update_error),
					checking = false
				)
			}

			runOnUiThread { updateState = result }
		}
	}

	private fun findLatestApkUrl(): String? {
		val json = JSONObject(readText("https://api.github.com/repos/Psych-Plus-Team/FNF-PlusEngine/releases/latest"))
		val assets = json.optJSONArray("assets") ?: return null
		for (i in 0 until assets.length()) {
			val asset = assets.optJSONObject(i) ?: continue
			val name = asset.optString("name")
			val url = asset.optString("browser_download_url")
			if (name.endsWith(".apk", ignoreCase = true) && url.isNotBlank()) return url
		}
		return null
	}

	private fun readText(url: String): String {
		val connection = (URL(url).openConnection() as HttpURLConnection).apply {
			connectTimeout = 8000
			readTimeout = 10000
			requestMethod = "GET"
			setRequestProperty("User-Agent", "PlusEngine-AndroidLauncher/${BuildConfig.VERSION_NAME}")
		}
		return connection.inputStream.bufferedReader().use { it.readText() }
	}

	private fun compareVersions(current: String, remote: String): Int {
		val a = current.cleanVersion().split(".").map { it.toIntOrNull() ?: 0 }
		val b = remote.cleanVersion().split(".").map { it.toIntOrNull() ?: 0 }
		for (i in 0 until maxOf(a.size, b.size, 3)) {
			val av = a.getOrElse(i) { 0 }
			val bv = b.getOrElse(i) { 0 }
			if (av != bv) return av.compareTo(bv)
		}
		return 0
	}

	private fun String.cleanVersion(): String {
		return substringBefore("-").substringBefore("+").replace(Regex("\\s*\\([^)]*\\)\\s*$"), "").trim()
	}

	private fun downloadUpdate() {
		val url = updateState.downloadUrl
		if (url.isNullOrBlank()) {
			Toast.makeText(this, R.string.plus_launcher_no_apk, Toast.LENGTH_LONG).show()
			return
		}

		val fileName = "PlusEngine-${updateState.latestVersion.ifBlank { "latest" }}.apk"
		val request = DownloadManager.Request(Uri.parse(url))
			.setTitle(fileName)
			.setDescription("Plus Engine")
			.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
			.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName)
			.setAllowedOverMetered(true)
			.setAllowedOverRoaming(true)

		val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
		manager.enqueue(request)
		Toast.makeText(this, R.string.plus_launcher_downloading, Toast.LENGTH_SHORT).show()
	}

	private fun openModInstaller() {
		val intent = findModInstallerIntent()
		if (intent == null) {
			Toast.makeText(this, R.string.plus_launcher_not_installed, Toast.LENGTH_LONG).show()
			return
		}
		startActivity(intent)
	}

	private fun findModInstallerIntent(): Intent? {
		val packageName = findModInstallerPackage() ?: return null
		val intent = packageManager.getLaunchIntentForPackage(packageName)
		if (intent != null) return intent

		val detailsIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
			.setData(Uri.parse("package:$packageName"))
		if (detailsIntent.resolveActivity(packageManager) != null) {
			return detailsIntent
		}
		return null
	}

	private fun findModInstallerPackage(): String? {
		for (packageName in modInstallerPackages) {
			if (isPackageInstalled(packageName)) return packageName
		}
		return null
	}

	private fun isPackageInstalled(packageName: String): Boolean {
		return runCatching {
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
				packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
			} else {
				@Suppress("DEPRECATION")
				packageManager.getPackageInfo(packageName, 0)
			}
		}.isSuccess
	}

	private fun openGithub() {
		runCatching {
			startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/Psych-Plus-Team/FNF-PlusEngine")))
		}
	}

	private fun setLanguage(languageTag: String) {
		AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(languageTag))
		recreate()
	}
}

private data class PermissionItem(
	val name: String,
	val status: PermissionStatus,
	val description: String
)

private enum class PermissionStatus {
	GRANTED,
	REQUIRED,
	NOT_NEEDED
}

private data class StorageItem(
	val label: String,
	val value: String
)

private data class FolderTarget(
	val documentUri: Uri,
	val rootUri: Uri
)

private data class UpdateState(
	val currentVersion: String = BuildConfig.VERSION_NAME,
	val latestVersion: String = "",
	val status: String = "",
	val downloadUrl: String? = null,
	val checking: Boolean = false,
	val hasUpdate: Boolean = false
)

@Composable
private fun LauncherTheme(content: @Composable () -> Unit) {
	val context = LocalContext.current
	val dark = isSystemInDarkTheme()
	val colorScheme = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
		if (dark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
	} else if (dark) {
		darkColorScheme(
			primary = Color(0xFFFFB15C),
			onPrimary = Color(0xFF2C1600),
			secondary = Color(0xFF74D7C3),
			tertiary = Color(0xFFFF8DA1),
			background = Color(0xFF101113),
			surface = Color(0xFF181B20),
			surfaceVariant = Color(0xFF232832),
			onBackground = Color(0xFFF6F0E8),
			onSurface = Color(0xFFF6F0E8),
			onSurfaceVariant = Color(0xFFC9CDD6)
		)
	} else {
		lightColorScheme(
			primary = Color(0xFF8D4D00),
			onPrimary = Color.White,
			secondary = Color(0xFF286B5E),
			tertiary = Color(0xFF934154),
			background = Color(0xFFFFFBFF),
			surface = Color(0xFFFFFBFF),
			surfaceVariant = Color(0xFFE8E0E9),
			onBackground = Color(0xFF1D1B20),
			onSurface = Color(0xFF1D1B20),
			onSurfaceVariant = Color(0xFF49454F)
		)
	}

	MaterialTheme(
		colorScheme = colorScheme,
		typography = Typography(),
		content = content
	)
}

@Composable
private fun LauncherScreen(
	permissions: List<PermissionItem>,
	storageRows: List<StorageItem>,
	updateState: UpdateState,
	modInstallerInstalled: Boolean,
	showLauncher: Boolean,
	autoStart: Boolean,
	onStartGame: () -> Unit,
	onShowLauncherChange: (Boolean) -> Unit,
	onAutoStartChange: (Boolean) -> Unit,
	onOpenData: () -> Unit,
	onOpenExternal: () -> Unit,
	onRequestPermissions: () -> Unit,
	onOpenSettings: () -> Unit,
	onCheckUpdates: () -> Unit,
	onDownloadUpdate: () -> Unit,
	onRefreshStorage: () -> Unit,
	onOpenModInstaller: () -> Unit,
	onOpenGithub: () -> Unit,
	onSetLanguage: (String) -> Unit
) {
	Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
		BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
			val compact = maxWidth < 720.dp
			val pagePadding = if (compact) 14.dp else 24.dp

			Box(
				modifier = Modifier
					.fillMaxSize()
					.background(
						Brush.linearGradient(
							listOf(
								MaterialTheme.colorScheme.background,
								MaterialTheme.colorScheme.surface,
								MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.38f)
							)
						)
					)
			) {
				LazyColumn(
					modifier = Modifier.fillMaxSize(),
					contentPadding = PaddingValues(pagePadding),
					verticalArrangement = Arrangement.spacedBy(14.dp)
				) {
					item {
						Header(onStartGame, compact)
					}

					item {
						LauncherCard(
							title = stringResource(R.string.plus_launcher_startup),
							icon = Icons.Rounded.PlayArrow,
							modifier = Modifier.fillMaxWidth()
						) {
							SettingSwitchRow(
								title = stringResource(R.string.plus_launcher_show_launcher),
								description = stringResource(R.string.plus_launcher_show_launcher_desc),
								checked = showLauncher,
								onCheckedChange = onShowLauncherChange
							)
							SettingSwitchRow(
								title = stringResource(R.string.plus_launcher_auto_start),
								description = stringResource(R.string.plus_launcher_auto_start_desc),
								checked = autoStart,
								onCheckedChange = onAutoStartChange
							)
						}
					}

					item {
						AdaptiveCardPair(
							compact = compact,
							first = { modifier ->
								LauncherCard(
									title = stringResource(R.string.plus_launcher_files),
									icon = Icons.Rounded.FolderOpen,
									modifier = modifier
								) {
									ActionRow {
										OutlinedButton(onClick = onOpenData, modifier = Modifier.weight(1f)) {
											Text(stringResource(R.string.plus_launcher_open_data), maxLines = 1, overflow = TextOverflow.Ellipsis)
										}
										OutlinedButton(onClick = onOpenExternal, modifier = Modifier.weight(1f)) {
											Text(stringResource(R.string.plus_launcher_open_external), maxLines = 1, overflow = TextOverflow.Ellipsis)
										}
									}
								}
							},
							second = { modifier ->
								LauncherCard(
									title = stringResource(R.string.plus_launcher_mod_installer),
									icon = Icons.AutoMirrored.Rounded.Launch,
									modifier = modifier
								) {
									StatusPill(
										text = if (modInstallerInstalled) stringResource(R.string.plus_launcher_installed) else stringResource(R.string.plus_launcher_not_installed),
										ok = modInstallerInstalled
									)
									Spacer(Modifier.height(12.dp))
									Button(onClick = onOpenModInstaller, modifier = Modifier.fillMaxWidth()) {
										Text(stringResource(R.string.plus_launcher_open_mod_installer), maxLines = 1, overflow = TextOverflow.Ellipsis)
									}
								}
							}
						)
					}

					item {
						AdaptiveCardPair(
							compact = compact,
							first = { modifier ->
								LauncherCard(
									title = stringResource(R.string.plus_launcher_permissions),
									icon = Icons.Rounded.Security,
									modifier = modifier
								) {
									permissions.forEach { PermissionRow(it) }
									Spacer(Modifier.height(12.dp))
									ActionRow {
										Button(onClick = onRequestPermissions, modifier = Modifier.weight(1f)) {
											Text(stringResource(R.string.plus_launcher_request_permissions), maxLines = 1, overflow = TextOverflow.Ellipsis)
										}
										OutlinedButton(onClick = onOpenSettings, modifier = Modifier.weight(1f)) {
											Text(stringResource(R.string.plus_launcher_open_settings), maxLines = 1, overflow = TextOverflow.Ellipsis)
										}
									}
								}
							},
							second = { modifier ->
								LauncherCard(
									title = stringResource(R.string.plus_launcher_updates),
									icon = Icons.Rounded.SystemUpdate,
									modifier = modifier
								) {
									Text(
										text = "${updateState.currentVersion} -> ${updateState.latestVersion.ifBlank { updateState.currentVersion }}",
										style = MaterialTheme.typography.bodyLarge,
										fontWeight = FontWeight.SemiBold
									)
									Text(
										text = updateState.status.ifBlank { stringResource(R.string.plus_launcher_ready) },
										color = MaterialTheme.colorScheme.onSurfaceVariant,
										style = MaterialTheme.typography.bodyMedium
									)
									Spacer(Modifier.height(12.dp))
									ActionRow {
										Button(onClick = onCheckUpdates, enabled = !updateState.checking, modifier = Modifier.weight(1f)) {
											Icon(Icons.Rounded.Refresh, contentDescription = null)
											Spacer(Modifier.width(8.dp))
											Text(stringResource(R.string.plus_launcher_check_updates), maxLines = 1, overflow = TextOverflow.Ellipsis)
										}
										OutlinedButton(
											onClick = onDownloadUpdate,
											enabled = updateState.downloadUrl != null,
											modifier = Modifier.weight(1f)
										) {
											Icon(Icons.Rounded.Download, contentDescription = null)
											Spacer(Modifier.width(8.dp))
											Text(stringResource(R.string.plus_launcher_download_update), maxLines = 1, overflow = TextOverflow.Ellipsis)
										}
									}
								}
							}
						)
					}

					item {
						AdaptiveCardPair(
							compact = compact,
							first = { modifier ->
								LauncherCard(
									title = stringResource(R.string.plus_launcher_storage),
									icon = Icons.Rounded.Storage,
									modifier = modifier
								) {
									storageRows.forEach { StorageRow(it) }
									Spacer(Modifier.height(12.dp))
									OutlinedButton(onClick = onRefreshStorage, modifier = Modifier.fillMaxWidth()) {
										Icon(Icons.Rounded.Refresh, contentDescription = null)
										Spacer(Modifier.width(8.dp))
										Text(stringResource(R.string.plus_launcher_refresh), maxLines = 1, overflow = TextOverflow.Ellipsis)
									}
								}
							},
							second = { modifier ->
								LauncherCard(
									title = stringResource(R.string.plus_launcher_language),
									icon = Icons.Rounded.Language,
									modifier = modifier
								) {
									ActionRow {
										OutlinedButton(onClick = { onSetLanguage("es") }, modifier = Modifier.weight(1f)) {
											Text(stringResource(R.string.plus_launcher_spanish), maxLines = 1, overflow = TextOverflow.Ellipsis)
										}
										OutlinedButton(onClick = { onSetLanguage("id") }, modifier = Modifier.weight(1f)) {
											Text(stringResource(R.string.plus_launcher_indonesian), maxLines = 1, overflow = TextOverflow.Ellipsis)
										}
										OutlinedButton(onClick = { onSetLanguage("en") }, modifier = Modifier.weight(1f)) {
											Text(stringResource(R.string.plus_launcher_english), maxLines = 1, overflow = TextOverflow.Ellipsis)
										}
									}
									Spacer(Modifier.height(12.dp))
									TextButton(onClick = onOpenGithub, modifier = Modifier.align(Alignment.End)) {
										Text(stringResource(R.string.plus_launcher_github), maxLines = 1, overflow = TextOverflow.Ellipsis)
										Spacer(Modifier.width(6.dp))
										Icon(Icons.AutoMirrored.Rounded.Launch, contentDescription = null, modifier = Modifier.size(18.dp))
									}
								}
							}
						)
					}
				}
			}
		}
	}
}

@Composable
private fun AdaptiveCardPair(
	compact: Boolean,
	first: @Composable (Modifier) -> Unit,
	second: @Composable (Modifier) -> Unit
) {
	if (compact) {
		Column(verticalArrangement = Arrangement.spacedBy(14.dp), modifier = Modifier.fillMaxWidth()) {
			first(Modifier.fillMaxWidth())
			second(Modifier.fillMaxWidth())
		}
	} else {
		Row(horizontalArrangement = Arrangement.spacedBy(16.dp), modifier = Modifier.fillMaxWidth()) {
			first(Modifier.weight(1f))
			second(Modifier.weight(1f))
		}
	}
}

@Composable
private fun Header(onStartGame: () -> Unit, compact: Boolean) {
	Card(
		modifier = Modifier.fillMaxWidth(),
		shape = RoundedCornerShape(if (compact) 26.dp else 32.dp),
		colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.94f)),
		border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.18f)),
		elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
	) {
		if (compact) {
			Column(
				modifier = Modifier
					.fillMaxWidth()
					.padding(18.dp),
				verticalArrangement = Arrangement.spacedBy(16.dp)
			) {
				Row(
					verticalAlignment = Alignment.CenterVertically,
					horizontalArrangement = Arrangement.spacedBy(14.dp)
				) {
					LauncherIcon(size = 54)
					Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
						LauncherTitle()
					}
				}

				StartGameButton(onStartGame, modifier = Modifier.fillMaxWidth())
			}
		} else {
			Row(
				modifier = Modifier
					.fillMaxWidth()
					.padding(22.dp),
				verticalAlignment = Alignment.CenterVertically,
				horizontalArrangement = Arrangement.spacedBy(18.dp)
			) {
				LauncherIcon(size = 64)

				Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
					LauncherTitle()
				}

				StartGameButton(onStartGame)
			}
		}
	}
}

@Composable
private fun LauncherIcon(size: Int) {
	Box(
		modifier = Modifier
			.size(size.dp)
			.clip(CircleShape)
			.background(MaterialTheme.colorScheme.primary.copy(alpha = 0.18f)),
		contentAlignment = Alignment.Center
	) {
		Icon(
			imageVector = Icons.Rounded.PlayArrow,
			contentDescription = null,
			tint = MaterialTheme.colorScheme.primary,
			modifier = Modifier.size((size * 0.65f).dp)
		)
	}
}

@Composable
private fun LauncherTitle() {
	Text(
		text = stringResource(R.string.plus_launcher_title),
		style = MaterialTheme.typography.headlineMedium,
		fontWeight = FontWeight.Black,
		maxLines = 2,
		overflow = TextOverflow.Ellipsis
	)
	Text(
		text = stringResource(R.string.plus_launcher_subtitle),
		style = MaterialTheme.typography.bodyLarge,
		color = MaterialTheme.colorScheme.onSurfaceVariant,
		maxLines = 2,
		overflow = TextOverflow.Ellipsis
	)
}

@Composable
private fun StartGameButton(onStartGame: () -> Unit, modifier: Modifier = Modifier) {
	Button(
		onClick = onStartGame,
		modifier = modifier,
		shape = RoundedCornerShape(24.dp),
		colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
		contentPadding = PaddingValues(horizontal = 24.dp, vertical = 16.dp)
	) {
		Icon(Icons.Rounded.PlayArrow, contentDescription = null)
		Spacer(Modifier.width(8.dp))
		Text(stringResource(R.string.plus_launcher_start_game), fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
	}
}

@Composable
private fun LauncherCard(
	title: String,
	icon: ImageVector,
	modifier: Modifier = Modifier,
	content: @Composable ColumnScope.() -> Unit
) {
	Card(
		modifier = modifier,
		shape = RoundedCornerShape(28.dp),
		colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.92f)),
		border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.12f))
	) {
		Column(modifier = Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
			Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
				Box(
					modifier = Modifier
						.size(38.dp)
						.clip(CircleShape)
						.background(MaterialTheme.colorScheme.secondary.copy(alpha = 0.14f)),
					contentAlignment = Alignment.Center
				) {
					Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.secondary)
				}
				Text(title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
			}
			Spacer(Modifier.height(4.dp))
			content()
		}
	}
}

@Composable
private fun SettingSwitchRow(
	title: String,
	description: String,
	checked: Boolean,
	onCheckedChange: (Boolean) -> Unit
) {
	Row(
		modifier = Modifier.fillMaxWidth(),
		verticalAlignment = Alignment.CenterVertically,
		horizontalArrangement = Arrangement.spacedBy(14.dp)
	) {
		Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
			Text(title, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurface)
			Text(description, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
		}
		Switch(checked = checked, onCheckedChange = onCheckedChange)
	}
}

@Composable
private fun ActionRow(content: @Composable RowScope.() -> Unit) {
	Row(
		modifier = Modifier.fillMaxWidth(),
		horizontalArrangement = Arrangement.spacedBy(10.dp),
		verticalAlignment = Alignment.CenterVertically,
		content = content
	)
}

@Composable
private fun PermissionRow(item: PermissionItem) {
	Row(
		modifier = Modifier.fillMaxWidth(),
		verticalAlignment = Alignment.CenterVertically,
		horizontalArrangement = Arrangement.spacedBy(10.dp)
	) {
		Column(modifier = Modifier.weight(1f)) {
			Text(item.name, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
			Text(item.description, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall, maxLines = 1, overflow = TextOverflow.Ellipsis)
		}
		StatusPill(
			text = when (item.status) {
				PermissionStatus.GRANTED -> stringResource(R.string.plus_launcher_granted)
				PermissionStatus.REQUIRED -> stringResource(R.string.plus_launcher_required)
				PermissionStatus.NOT_NEEDED -> stringResource(R.string.plus_launcher_not_needed)
			},
			ok = item.status != PermissionStatus.REQUIRED
		)
	}
}

@Composable
private fun StorageRow(item: StorageItem) {
	Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
		Text(item.label, color = MaterialTheme.colorScheme.onSurfaceVariant)
		Text(item.value, fontWeight = FontWeight.SemiBold)
	}
}

@Composable
private fun StatusPill(text: String, ok: Boolean) {
	val color = if (ok) MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.tertiary
	Surface(
		shape = RoundedCornerShape(999.dp),
		color = color.copy(alpha = 0.16f),
		border = BorderStroke(1.dp, color.copy(alpha = 0.35f))
	) {
		Text(
			text = text,
			modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp),
			color = color,
			style = MaterialTheme.typography.labelMedium,
			fontWeight = FontWeight.Bold
		)
	}
}
