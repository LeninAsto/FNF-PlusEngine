package mobile.backend;

import lime.app.Application;

class SoftKeyboard
{
	static var onText:String->Void;
	static var onBackspace:Void->Void;
	static var onClose:Void->Void;
	static var opened:Bool = false;

	public static function open(text:String->Void, backspace:Void->Void, closeCallback:Void->Void):Void
	{
		close(false);
		onText = text;
		onBackspace = backspace;
		onClose = closeCallback;
		opened = true;

		var window = Application.current != null ? Application.current.window : null;
		if (window == null)
			return;

		window.onTextInput.add(handleTextInput);
		window.textInputEnabled = true;
	}

	public static function close(?callClose:Bool = true):Void
	{
		var wasOpened:Bool = opened;
		opened = false;

		var window = Application.current != null ? Application.current.window : null;
		if (window != null)
		{
			window.onTextInput.remove(handleTextInput);
			window.textInputEnabled = false;
		}

		if (callClose && wasOpened && onClose != null)
			onClose();

		onText = null;
		onBackspace = null;
		onClose = null;
	}

	static function handleTextInput(input:String):Void
	{
		if (!opened || input == null || input.length < 1)
			return;

		if (input.charCodeAt(0) == 8 || input.charCodeAt(0) == 127)
		{
			if (onBackspace != null)
				onBackspace();
			return;
		}

		if (onText != null)
			onText(input);
	}
}
