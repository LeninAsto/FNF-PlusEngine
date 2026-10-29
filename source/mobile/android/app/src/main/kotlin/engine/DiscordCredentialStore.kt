package ::APP_PACKAGE::

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.haxe.extension.Extension
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Encrypts Discord OAuth tokens with an app-local Android Keystore key. */
object DiscordCredentialStore {
	private const val KEYSTORE = "AndroidKeyStore"
	private const val KEY_ALIAS = "plus_engine_discord_oauth"
	private const val PREFS = "discord_secure_credentials"

	@JvmStatic
	fun available(): Boolean = runCatching {
		if (context() == null) false else {
			getOrCreateKey()
			true
		}
	}.getOrDefault(false)

	@JvmStatic
	fun write(key: String?, value: String?): Boolean {
		if (key.isNullOrBlank() || value == null) return false
		val context = context() ?: return false
		return runCatching {
			val cipher = Cipher.getInstance("AES/GCM/NoPadding")
			cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey())
			cipher.updateAAD(key.toByteArray(Charsets.UTF_8))
			val iv = Base64.encodeToString(cipher.iv, Base64.NO_WRAP)
			val payload = Base64.encodeToString(cipher.doFinal(value.toByteArray(Charsets.UTF_8)), Base64.NO_WRAP)
			context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(key, "$iv:$payload").commit()
		}.getOrDefault(false)
	}

	@JvmStatic
	fun read(key: String?): String? {
		if (key.isNullOrBlank()) return null
		val context = context() ?: return null
		return runCatching {
			val stored = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(key, null) ?: return null
			val separator = stored.indexOf(':')
			if (separator <= 0) return null
			val cipher = Cipher.getInstance("AES/GCM/NoPadding")
			cipher.init(Cipher.DECRYPT_MODE, getOrCreateKey(), GCMParameterSpec(128, Base64.decode(stored.substring(0, separator), Base64.NO_WRAP)))
			cipher.updateAAD(key.toByteArray(Charsets.UTF_8))
			String(cipher.doFinal(Base64.decode(stored.substring(separator + 1), Base64.NO_WRAP)), Charsets.UTF_8)
		}.getOrNull()
	}

	@JvmStatic
	fun remove(key: String?): Boolean {
		if (key.isNullOrBlank()) return false
		val context = context() ?: return false
		return runCatching {
			context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(key).commit()
		}.getOrDefault(false)
	}

	private fun context(): Context? = Extension.mainContext ?: Extension.mainActivity?.applicationContext

	private fun getOrCreateKey(): SecretKey {
		val keyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }
		(keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
		val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
		generator.init(
			KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
				.setBlockModes(KeyProperties.BLOCK_MODE_GCM)
				.setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
				.setKeySize(256)
				.build()
		)
		return generator.generateKey()
	}
}
