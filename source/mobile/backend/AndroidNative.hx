package mobile.backend;

#if android
import android.Tools;
import android.widget.Toast;
#end

class AndroidNative
{
	public static function showAlert(title:String, message:String):Bool
	{
		#if android
		try
		{
			backend.ThreadUtil.execAsync(function()
			{
				try
					Tools.showAlertDialog(title, message, {name: "OK", func: null}, null)
				catch(e:Dynamic)
					trace('Android alert dialog failed: $e');
			});
			return true;
		}
		catch(e:Dynamic)
		{
			trace('Android alert dispatch failed: $e');
		}
		#end
		return false;
	}

	public static function showToast(message:String, ?long:Bool = false, ?xOffset:Int = 0, ?yOffset:Int = 0):Bool
	{
		if (message == null || message.length == 0)
			return false;

		#if android
		try
		{
			Toast.makeText(message, long ? 1 : 0, -1, xOffset, yOffset);
			return true;
		}
		catch(e:Dynamic)
		{
			trace('Android toast failed: $e');
		}
		#end
		return false;
	}

	public static function showNotification(title:String, message:String, ?channelID:String = 'plus_engine', ?channelName:String = 'Plus Engine', ?id:Int = 1):Bool
	{
		#if android
		try
		{
			Tools.showNotification(title, message, channelID, channelName, id);
			return true;
		}
		catch(e:Dynamic)
		{
			trace('Android notification failed: $e');
		}
		#end
		return false;
	}
}
