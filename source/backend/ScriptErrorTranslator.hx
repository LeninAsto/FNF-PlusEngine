package backend;

/**
 * Localizes the human-readable part of diagnostics emitted by Lua and HScript.
 * File names, line numbers, function names and source tokens deliberately stay
 * untouched: they are part of the scripting API and of a useful bug report.
 */
class ScriptErrorTranslator
{
	static final LUA_NIL_INDEX:EReg = ~/attempt to index a nil value/g;
	static final LUA_NIL_CALL:EReg = ~/attempt to call a nil value/g;
	static final LUA_NIL_ARITHMETIC:EReg = ~/attempt to perform arithmetic on a nil value/g;
	static final LUA_SYNTAX_NEAR:EReg = ~/syntax error near ([^\r\n]+)/g;
	static final HSCRIPT_UNKNOWN_IDENTIFIER:EReg = ~/Unknown identifier(?:\s*:\s*|\s+)([^\r\n]+)/g;
	static final HSCRIPT_NULL_FIELD:EReg = ~/Null reference: trying to access "([^"]+)" on null object/g;
	static final HSCRIPT_MISSING_FUNCTION:EReg = ~/No function named:\s*([^\r\n]+)/g;
	static final HSCRIPT_INVALID_CHARACTER:EReg = ~/Invalid character:\s*(.+)/g;
	static final HSCRIPT_UNEXPECTED_TOKEN:EReg = ~/Unexpected token:\s*"([^"]+)"/g;
	static final HSCRIPT_INVALID_PREPROCESSOR:EReg = ~/Invalid preprocessor \(([^)]+)\)/g;
	static final HSCRIPT_INVALID_ITERATOR:EReg = ~/Invalid iterator:\s*([^\r\n]+)/g;
	static final HSCRIPT_INVALID_OPERATOR:EReg = ~/Invalid operator:\s*([^\r\n]+)/g;
	static final HSCRIPT_INVALID_ACCESS:EReg = ~/Invalid access to field\s+([^\r\n]+)/g;
	static final HSCRIPT_INVALID_CLASS:EReg = ~/Invalid or unknown class:\s*([^\r\n]+)/g;
	static final HSCRIPT_INVALID_PARAMETER_COUNT:EReg = ~/Invalid number of parameters\. Got (\d+), required (\d+)/g;

	public static function lua(message:String):String
	{
		if (message == null || message.length == 0)
			return message;

		message = LUA_NIL_INDEX.map(message, function(_)
			return Language.getPhrase('errors.scripting.lua.nil_index', 'attempt to index a nil value'));
		message = LUA_NIL_CALL.map(message, function(_)
			return Language.getPhrase('errors.scripting.lua.nil_call', 'attempt to call a nil value'));
		message = LUA_NIL_ARITHMETIC.map(message, function(_)
			return Language.getPhrase('errors.scripting.lua.nil_arithmetic', 'attempt to perform arithmetic on a nil value'));
		return LUA_SYNTAX_NEAR.map(message, function(_)
			return Language.getPhrase('errors.scripting.lua.syntax_near', 'syntax error near {1}', [LUA_SYNTAX_NEAR.matched(1)]));
	}

	public static function hscript(message:String):String
	{
		if (message == null || message.length == 0)
			return message;

		message = HSCRIPT_UNKNOWN_IDENTIFIER.map(message, function(_)
			return Language.getPhrase('errors.scripting.hscript.unknown_identifier', 'Unknown identifier: {1}', [HSCRIPT_UNKNOWN_IDENTIFIER.matched(1)]));
		message = HSCRIPT_NULL_FIELD.map(message, function(_)
			return Language.getPhrase('errors.scripting.hscript.null_field', 'Null reference: trying to access "{1}" on null object', [HSCRIPT_NULL_FIELD.matched(1)]));
		message = HSCRIPT_MISSING_FUNCTION.map(message, function(_)
			return Language.getPhrase('errors.scripting.hscript.missing_function', 'No function named: {1}', [HSCRIPT_MISSING_FUNCTION.matched(1)]));
		message = HSCRIPT_INVALID_CHARACTER.map(message, function(_)
			return Language.getPhrase('errors.scripting.hscript.invalid_character', 'Invalid character: {1}', [HSCRIPT_INVALID_CHARACTER.matched(1)]));
		message = HSCRIPT_UNEXPECTED_TOKEN.map(message, function(_)
			return Language.getPhrase('errors.scripting.hscript.unexpected_token', 'Unexpected token: "{1}"', [HSCRIPT_UNEXPECTED_TOKEN.matched(1)]));
		message = HSCRIPT_INVALID_PREPROCESSOR.map(message, function(_)
			return Language.getPhrase('errors.scripting.hscript.invalid_preprocessor', 'Invalid preprocessor ({1})', [HSCRIPT_INVALID_PREPROCESSOR.matched(1)]));
		message = HSCRIPT_INVALID_ITERATOR.map(message, function(_)
			return Language.getPhrase('errors.scripting.hscript.invalid_iterator', 'Invalid iterator: {1}', [HSCRIPT_INVALID_ITERATOR.matched(1)]));
		message = HSCRIPT_INVALID_OPERATOR.map(message, function(_)
			return Language.getPhrase('errors.scripting.hscript.invalid_operator', 'Invalid operator: {1}', [HSCRIPT_INVALID_OPERATOR.matched(1)]));
		message = HSCRIPT_INVALID_ACCESS.map(message, function(_)
			return Language.getPhrase('errors.scripting.hscript.invalid_access', 'Invalid access to field {1}', [HSCRIPT_INVALID_ACCESS.matched(1)]));
		message = HSCRIPT_INVALID_CLASS.map(message, function(_)
			return Language.getPhrase('errors.scripting.hscript.invalid_class', 'Invalid or unknown class: {1}', [HSCRIPT_INVALID_CLASS.matched(1)]));
		return HSCRIPT_INVALID_PARAMETER_COUNT.map(message, function(_)
			return Language.getPhrase('errors.scripting.hscript.invalid_parameter_count', 'Invalid number of parameters. Got {1}, required {2}', [HSCRIPT_INVALID_PARAMETER_COUNT.matched(1), HSCRIPT_INVALID_PARAMETER_COUNT.matched(2)]));
	}
}
