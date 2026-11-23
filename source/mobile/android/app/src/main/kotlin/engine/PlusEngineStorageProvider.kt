package ::APP_PACKAGE::

import android.database.Cursor
import android.database.MatrixCursor
import android.provider.DocumentsContract.Root
import org.haxe.lime.StorageProvider

/**
 * Gives the engine's Storage Access Framework root its actual launcher icon.
 * The base Lime provider continues handling all file access and mutations.
 */
class PlusEngineStorageProvider : StorageProvider() {
	private companion object {
		val ROOT_PROJECTION = arrayOf(
			Root.COLUMN_ROOT_ID,
			Root.COLUMN_MIME_TYPES,
			Root.COLUMN_FLAGS,
			Root.COLUMN_ICON,
			Root.COLUMN_TITLE,
			Root.COLUMN_SUMMARY,
			Root.COLUMN_DOCUMENT_ID
		)
	}

	override fun queryRoots(projection: Array<String>?): Cursor {
		val result = MatrixCursor(projection ?: ROOT_PROJECTION)
		val appContext = context ?: return result
		val baseDir = appContext.getExternalFilesDir(null) ?: return result
		val rootId = baseDir.absolutePath
		val appInfo = appContext.applicationInfo
		val title = appContext.packageManager.getApplicationLabel(appInfo).toString()

		result.newRow().apply {
			add(Root.COLUMN_ROOT_ID, rootId)
			add(Root.COLUMN_DOCUMENT_ID, rootId)
			add(Root.COLUMN_SUMMARY, null)
			add(Root.COLUMN_FLAGS, Root.FLAG_SUPPORTS_CREATE or Root.FLAG_SUPPORTS_SEARCH or Root.FLAG_SUPPORTS_IS_CHILD)
			add(Root.COLUMN_TITLE, title)
			add(Root.COLUMN_MIME_TYPES, "*/*")
			add(Root.COLUMN_ICON, R.mipmap.ic_launcher)
		}
		return result
	}
}
