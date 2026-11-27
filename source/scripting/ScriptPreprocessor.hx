package scripting;

#if HSCRIPT_ALLOWED
using StringTools;

class ScriptPreprocessor {
	public static function process(code:String):String {
		if (code == null)
			return code;
		code = redirectLegacyImports(code);

		if (code.indexOf('#if') == -1)
			return normalizeScriptSyntax(code);

		var out:Array<String> = [];
		var stack:Array<ConditionalFrame> = [];
		var lines:Array<String> = code.split('\n');

		for (line in lines) {
			var trimmed:String = line.trim();
			var directive:Directive = parseLineDirective(trimmed);
			if (directive != null) {
				switch (directive.kind) {
					case If:
						var parentActive:Bool = isActive(stack);
						var branchActive:Bool = parentActive && eval(directive.condition);
						stack.push({
							parentActive: parentActive,
							active: branchActive,
							matched: branchActive
						});
					case ElseIf:
						if (stack.length > 0) {
							var frame:ConditionalFrame = stack[stack.length - 1];
							if (!frame.parentActive || frame.matched)
								frame.active = false;
							else {
								frame.active = eval(directive.condition);
								frame.matched = frame.active;
							}
						}
					case Else:
						if (stack.length > 0) {
							var frame:ConditionalFrame = stack[stack.length - 1];
							frame.active = frame.parentActive && !frame.matched;
							frame.matched = true;
						}
					case End:
						if (stack.length > 0)
							stack.pop();
				}
				continue;
			}

			if (isActive(stack))
				out.push(processInline(line));
		}

		return normalizeScriptSyntax(out.join('\n'));
	}

	public static function redirectLegacyImports(code:String):String {
		if (code == null || code.indexOf('import tjson.TJSON') < 0) return code;
		var lines = code.split('\n');
		for (i in 0...lines.length) {
			var trimmed = lines[i].trim();
			if (trimmed.startsWith('import tjson.TJSON;'))
				lines[i] = lines[i].replace('import tjson.TJSON;', 'import deprecations.tjson.LegacyTJSON as TJSON;');
			else if (trimmed.startsWith('import tjson.TJSON as '))
				lines[i] = lines[i].replace('import tjson.TJSON as ', 'import deprecations.tjson.LegacyTJSON as ');
		}
		return lines.join('\n');
	}

	public static function adaptFriendlyClassName(code:String, scriptedPath:String):String {
		if (code == null || scriptedPath == null)
			return code;

		var parts:Array<String> = scriptedPath.split('.');
		var expected:String = parts.length > 0 ? parts[parts.length - 1] : '';
		if (!expected.endsWith('Script') || expected.length <= 'Script'.length)
			return code;

		var friendly:String = expected.substr(0, expected.length - 'Script'.length);
		if (friendly.length < 1 || code.indexOf('class $friendly') == -1)
			return code;

		var lines:Array<String> = code.split('\n');
		for (i in 0...lines.length) {
			var line:String = lines[i];
			var at:Int = line.indexOf('class $friendly');
			if (at < 0)
				continue;

			var beforeOk:Bool = at == 0 || !isIdentChar(line.charAt(at - 1));
			var after:Int = at + 'class '.length + friendly.length;
			var afterOk:Bool = after >= line.length || !isIdentChar(line.charAt(after));
			if (beforeOk && afterOk) {
				lines[i] = line.substring(0, at) + 'class $expected' + line.substr(after);
				return lines.join('\n');
			}
		}

		return code;
	}

	static function normalizeScriptSyntax(code:String):String {
		var out:Array<String> = [];
		var lines:Array<String> = code.split('\n');
		var inTypedef:Bool = false;
		var typedefBodyStarted:Bool = false;
		var depth:Int = 0;

		for (line in lines) {
			var trimmed:String = line.trim();
			if (!inTypedef && trimmed.startsWith('typedef ')) {
				inTypedef = true;
				typedefBodyStarted = line.indexOf('{') >= 0;
				depth = braceDelta(line);
			} else if (inTypedef) {
				if (line.indexOf('{') >= 0)
					typedefBodyStarted = true;
				depth += braceDelta(line);
			}

			if (inTypedef)
				line = StringTools.replace(line, 'public var ', 'var ');

			out.push(line);

			if (inTypedef && typedefBodyStarted && depth <= 0) {
				inTypedef = false;
				typedefBodyStarted = false;
			}
		}

		return out.join('\n');
	}

	static function braceDelta(line:String):Int {
		var delta:Int = 0;
		for (i in 0...line.length) {
			var ch:String = line.charAt(i);
			if (ch == '{')
				delta++;
			else if (ch == '}')
				delta--;
		}
		return delta;
	}

	static function parseLineDirective(trimmed:String):Directive {
		if (!trimmed.startsWith('#'))
			return null;

		// Inline directives like "#if windows doThing(); #end" must be handled
		// by processInline(), otherwise the block stack stays open until EOF.
		if (trimmed.indexOf('#end') > 0 || trimmed.indexOf('#else') > 0)
			return null;

		var directiveText:String = stripDirectiveComment(trimmed);
		if (directiveText.startsWith('#if '))
			return {kind: If, condition: cleanCondition(directiveText.substr(4))};
		if (directiveText.startsWith('#elseif '))
			return {kind: ElseIf, condition: cleanCondition(directiveText.substr(8))};
		if (directiveText == '#else')
			return {kind: Else, condition: ''};
		if (directiveText == '#end')
			return {kind: End, condition: ''};
		return null;
	}

	static function stripDirectiveComment(line:String):String {
		var commentAt:Int = line.indexOf('//');
		return (commentAt >= 0 ? line.substr(0, commentAt) : line).trim();
	}

	static function processInline(line:String):String {
		var cursor:Int = 0;
		var output:StringBuf = new StringBuf();

		while (true) {
			var start:Int = line.indexOf('#if', cursor);
			if (start < 0) {
				output.add(line.substr(cursor));
				break;
			}

			output.add(line.substring(cursor, start));
			var parsed:InlineConditional = parseInline(line, start);
			if (parsed == null) {
				output.add(line.substr(start, 3));
				cursor = start + 3;
				continue;
			}

			output.add(parsed.keep ? parsed.body : '');
			cursor = parsed.end;
		}

		return output.toString();
	}

	static function parseInline(line:String, start:Int):InlineConditional {
		var i:Int = start + 3;
		if (i < line.length && !isSpace(line.charAt(i)))
			return null;
		while (i < line.length && isSpace(line.charAt(i)))
			i++;

		var conditionStart:Int = i;
		if (i < line.length && line.charAt(i) == '(') {
			var depth:Int = 0;
			while (i < line.length) {
				var ch:String = line.charAt(i);
				if (ch == '(')
					depth++;
				else if (ch == ')') {
					depth--;
					if (depth == 0) {
						i++;
						break;
					}
				}
				i++;
			}
		} else {
			if (i < line.length && line.charAt(i) == '!')
				i++;
			while (i < line.length && isIdentChar(line.charAt(i)))
				i++;
		}

		var condition:String = cleanCondition(line.substring(conditionStart, i));
		while (i < line.length && isSpace(line.charAt(i)))
			i++;
		if (line.substr(i, 4) == 'then') {
			i += 4;
			while (i < line.length && isSpace(line.charAt(i)))
				i++;
		}

		var elseAt:Int = findDirective(line, '#else', i);
		var endAt:Int = findDirective(line, '#end', i);
		if (endAt < 0)
			return null;

		var keep:Bool = eval(condition);
		var body:String;
		if (elseAt >= 0 && elseAt < endAt) {
			body = keep ? line.substring(i, elseAt) : line.substring(elseAt + 5, endAt);
		} else {
			body = keep ? line.substring(i, endAt) : '';
		}

		return {body: body, keep: true, end: endAt + 4};
	}

	static function findDirective(line:String, directive:String, from:Int):Int {
		var at:Int = line.indexOf(directive, from);
		while (at >= 0) {
			var after:Int = at + directive.length;
			if (after >= line.length || isSpace(line.charAt(after)))
				return at;
			at = line.indexOf(directive, after);
		}
		return -1;
	}

	static inline function isActive(stack:Array<ConditionalFrame>):Bool
		return stack.length == 0 || stack[stack.length - 1].active;

	static function cleanCondition(condition:String):String {
		condition = condition.trim();
		if (condition.endsWith(' then'))
			condition = condition.substr(0, condition.length - 5).trim();
		return condition;
	}

	static function eval(condition:String):Bool {
		var parser:ConditionParser = new ConditionParser(tokenize(condition));
		return parser.parseOr();
	}

	static function tokenize(condition:String):Array<String> {
		var tokens:Array<String> = [];
		var i:Int = 0;
		while (i < condition.length) {
			var ch:String = condition.charAt(i);
			if (isSpace(ch)) {
				i++;
				continue;
			}
			if (ch == '(' || ch == ')' || ch == '!') {
				tokens.push(ch);
				i++;
				continue;
			}
			if ((ch == '&' || ch == '|') && i + 1 < condition.length && condition.charAt(i + 1) == ch) {
				tokens.push(ch + ch);
				i += 2;
				continue;
			}

			var start:Int = i;
			while (i < condition.length && isIdentChar(condition.charAt(i)))
				i++;
			if (i == start)
				i++;
			else
				tokens.push(condition.substring(start, i));
		}
		return tokens;
	}

	public static function defineValue(name:String):Bool {
		return switch (name) {
			case 'true': true;
			case 'false': false;
			case 'mobile': #if mobile true #else false #end;
			case 'android': #if android true #else false #end;
			case 'ios': #if ios true #else false #end;
			case 'desktop': #if desktop true #else false #end;
			case 'windows': #if windows true #else false #end;
			case 'linux': #if linux true #else false #end;
			case 'mac' | 'macos': #if (mac || macos) true #else false #end;
			case 'html5': #if html5 true #else false #end;
			case 'js': #if js true #else false #end;
			case 'cpp': #if cpp true #else false #end;
			case 'hl': #if hl true #else false #end;
			case 'sys': #if sys true #else false #end;
			case 'debug': #if debug true #else false #end;
			case 'release': #if !debug true #else false #end;
			case 'MODS_ALLOWED': #if MODS_ALLOWED true #else false #end;
			case 'LUA_ALLOWED': #if LUA_ALLOWED true #else false #end;
			case 'HSCRIPT_ALLOWED': #if HSCRIPT_ALLOWED true #else false #end;
			case 'VIDEOS_ALLOWED': #if VIDEOS_ALLOWED true #else false #end;
			case 'DISCORD_ALLOWED': #if DISCORD_ALLOWED true #else false #end;
			case 'ACHIEVEMENTS_ALLOWED': #if ACHIEVEMENTS_ALLOWED true #else false #end;
			case 'TRANSLATIONS_ALLOWED': #if TRANSLATIONS_ALLOWED true #else false #end;
			case 'target.threaded': #if (target.threaded) true #else false #end;
			default: false;
		}
	}

	static inline function isSpace(ch:String):Bool
		return ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n';

	static inline function isIdentChar(ch:String):Bool
		return (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') || ch == '_' || ch == '.';
}

private class ConditionParser {
	var tokens:Array<String>;
	var pos:Int = 0;

	public function new(tokens:Array<String>) {
		this.tokens = tokens;
	}

	public function parseOr():Bool {
		var value:Bool = parseAnd();
		while (match('||'))
			value = parseAnd() || value;
		return value;
	}

	function parseAnd():Bool {
		var value:Bool = parseUnary();
		while (match('&&'))
			value = parseUnary() && value;
		return value;
	}

	function parseUnary():Bool {
		if (match('!'))
			return !parseUnary();
		if (match('(')) {
			var value:Bool = parseOr();
			match(')');
			return value;
		}

		if (pos >= tokens.length)
			return false;
		return ScriptPreprocessor.defineValue(tokens[pos++]);
	}

	function match(token:String):Bool {
		if (pos < tokens.length && tokens[pos] == token) {
			pos++;
			return true;
		}
		return false;
	}
}

private enum DirectiveKind {
	If;
	ElseIf;
	Else;
	End;
}

private typedef Directive = {
	var kind:DirectiveKind;
	var condition:String;
}

private typedef ConditionalFrame = {
	var parentActive:Bool;
	var active:Bool;
	var matched:Bool;
}

private typedef InlineConditional = {
	var body:String;
	var keep:Bool;
	var end:Int;
}
#end
