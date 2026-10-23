package objects;

#if (MODS_ALLOWED && sys && !mobile)
import backend.ThreadUtil;
import backend.ui.md3.MaterialWavyProgressIndicator;
import backend.ui.md3.MaterialWavyProgressIndicator.WavyProgressType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.io.Bytes;
import haxe.io.Eof;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.thread.Mutex;

private typedef ModImportFile =
{
	var source:String;
	var relative:String;
	var size:Float;
}

private typedef ModImportSnapshot =
{
	var phase:Int;
	var copiedBytes:Float;
	var totalBytes:Float;
	var copiedFiles:Int;
	var totalFiles:Int;
	var currentFile:String;
	var finished:Bool;
	var succeeded:Bool;
	var errorMessage:String;
}

/** Non-blocking desktop mod-folder import with a thread-safe progress snapshot. */
class ModImportOverlay extends FlxSpriteGroup
{
	public var finished(default, null):Bool = false;
	public var succeeded(default, null):Bool = false;
	public var errorMessage(default, null):String = '';

	var task:ModImportTask;
	var indicator:MaterialWavyProgressIndicator;
	var titleText:FlxText;
	var statusText:FlxText;
	var percentText:FlxText;
	var detailText:FlxText;

	public function new(source:String, target:String, folderName:String)
	{
		super();
		scrollFactor.set();

		var shade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xD9000000);
		shade.scrollFactor.set();
		add(shade);

		var cardWidth:Int = 560;
		var cardHeight:Int = 286;
		var card = new FlxSprite((FlxG.width - cardWidth) * 0.5, (FlxG.height - cardHeight) * 0.5)
			.makeGraphic(cardWidth, cardHeight, 0xFF171A21);
		card.scrollFactor.set();
		add(card);

		titleText = makeCenteredText(card.y + 28, 28);
		titleText.text = Language.getPhrase('freeplay.mod_import.title', 'Importing mod');
		add(titleText);

		statusText = makeCenteredText(card.y + 70, 18);
		statusText.text = folderName;
		statusText.color = 0xFFD7D9E0;
		add(statusText);

		indicator = new MaterialWavyProgressIndicator((FlxG.width - 88) * 0.5, card.y + 108, WavyProgressType.CIRCULAR, 88);
		indicator.indeterminate = true;
		indicator.value = 0;
		add(indicator);

		percentText = makeCenteredText(card.y + 137, 20);
		percentText.text = '...';
		add(percentText);

		detailText = makeCenteredText(card.y + 220, 16);
		detailText.color = 0xFFB9BBC5;
		detailText.text = Language.getPhrase('freeplay.mod_import.scanning', 'Scanning files...');
		add(detailText);

		task = new ModImportTask(source, target);
		task.start();
	}

	function makeCenteredText(y:Float, size:Int):FlxText
	{
		var text = new FlxText(0, y, FlxG.width, '', size);
		text.setFormat(Paths.font('vcr.ttf'), size, FlxColor.WHITE, CENTER);
		text.scrollFactor.set();
		return text;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (task == null || finished)
			return;

		var snapshot = task.snapshot();
		finished = snapshot.finished;
		succeeded = snapshot.succeeded;
		errorMessage = snapshot.errorMessage;

		if (snapshot.phase == ModImportTask.SCANNING)
		{
			indicator.indeterminate = true;
			percentText.text = '...';
			detailText.text = Language.getPhrase('freeplay.mod_import.scanning', 'Scanning files...');
			return;
		}

		indicator.indeterminate = false;
		var progress:Float = snapshot.totalBytes > 0 ? snapshot.copiedBytes / snapshot.totalBytes :
			(snapshot.totalFiles > 0 ? snapshot.copiedFiles / snapshot.totalFiles : (snapshot.succeeded ? 1 : 0));
		indicator.value = progress;
		percentText.text = '${Math.floor(progress * 100)}%';

		if (!snapshot.finished)
		{
			var fileName = snapshot.currentFile == null || snapshot.currentFile.length == 0 ? '' : '\n' + snapshot.currentFile;
			detailText.text = Language.getPhrase('freeplay.mod_import.copying', 'Copying {1} of {2} files',
				[snapshot.copiedFiles, snapshot.totalFiles]) + fileName;
		}
		else if (snapshot.succeeded)
		{
			indicator.value = 1;
			percentText.text = '100%';
			detailText.text = Language.getPhrase('freeplay.mod_import.complete', 'Import complete. Refreshing mods...');
		}
		else
		{
			statusText.color = 0xFFFF8A80;
			statusText.text = Language.getPhrase('freeplay.mod_import.failed', 'The mod could not be imported');
			detailText.text = errorMessage + '\n' + Language.getPhrase('freeplay.mod_import.dismiss', 'Press ACCEPT or BACK to close');
		}
	}
}

private class ModImportTask
{
	public static inline var SCANNING:Int = 0;
	public static inline var COPYING:Int = 1;
	public static inline var COMPLETE:Int = 2;
	public static inline var FAILED:Int = 3;

	static inline var COPY_BUFFER_SIZE:Int = 1024 * 1024;

	var source:String;
	var target:String;
	var mutex:Mutex = new Mutex();
	var phase:Int = SCANNING;
	var copiedBytes:Float = 0;
	var totalBytes:Float = 0;
	var copiedFiles:Int = 0;
	var totalFiles:Int = 0;
	var currentFile:String = '';
	var finished:Bool = false;
	var succeeded:Bool = false;
	var errorMessage:String = '';

	public function new(source:String, target:String)
	{
		this.source = source;
		this.target = target;
	}

	public function start():Void
	{
		#if target.threaded
		ThreadUtil.execAsync(run);
		#else
		run();
		#end
	}

	public function snapshot():ModImportSnapshot
	{
		mutex.acquire();
		var result:ModImportSnapshot = {
			phase: phase,
			copiedBytes: copiedBytes,
			totalBytes: totalBytes,
			copiedFiles: copiedFiles,
			totalFiles: totalFiles,
			currentFile: currentFile,
			finished: finished,
			succeeded: succeeded,
			errorMessage: errorMessage
		};
		mutex.release();
		return result;
	}

	function run():Void
	{
		try
		{
			var sourceFull = FileSystem.fullPath(source).replace('\\', '/');
			var targetFull = FileSystem.fullPath(target).replace('\\', '/');
			#if windows
			sourceFull = sourceFull.toLowerCase();
			targetFull = targetFull.toLowerCase();
			#end
			if (sourceFull == targetFull)
			{
				complete(true);
				return;
			}

			var files:Array<ModImportFile> = [];
			var visited:Map<String, Bool> = [];
			scanDirectory(source, '', files, visited);

			mutex.acquire();
			totalFiles = files.length;
			for (file in files)
				totalBytes += file.size;
			phase = COPYING;
			mutex.release();

			if (!FileSystem.exists(target))
				FileSystem.createDirectory(target);
			for (file in files)
			{
				mutex.acquire();
				currentFile = file.relative;
				mutex.release();

				var destination = Path.join([target, file.relative]);
				var parent = Path.directory(destination);
				if (parent != null && parent.length > 0 && !FileSystem.exists(parent))
					FileSystem.createDirectory(parent);
				copyFile(file.source, destination);

				mutex.acquire();
				copiedFiles++;
				mutex.release();
			}
			complete(true);
		}
		catch (error:Dynamic)
		{
			mutex.acquire();
			phase = FAILED;
			finished = true;
			succeeded = false;
			errorMessage = Std.string(error);
			mutex.release();
		}
	}

	function scanDirectory(directory:String, relative:String, files:Array<ModImportFile>, visited:Map<String, Bool>):Void
	{
		var full = FileSystem.fullPath(directory).replace('\\', '/');
		#if windows full = full.toLowerCase(); #end
		if (visited.exists(full))
			return;
		visited.set(full, true);

		for (entry in FileSystem.readDirectory(directory))
		{
			var sourcePath = Path.join([directory, entry]);
			var relativePath = relative.length > 0 ? Path.join([relative, entry]) : entry;
			if (FileSystem.isDirectory(sourcePath))
				scanDirectory(sourcePath, relativePath, files, visited);
			else
			{
				var size:Float = 0;
				try size = FileSystem.stat(sourcePath).size catch (_:Dynamic) {}
				files.push({source: sourcePath, relative: relativePath, size: size});
			}
		}
	}

	function copyFile(sourcePath:String, destination:String):Void
	{
		var input = File.read(sourcePath, true);
		var output = File.write(destination, true);
		var buffer = Bytes.alloc(COPY_BUFFER_SIZE);
		var failure:Dynamic = null;
		try
		{
			while (true)
			{
				var count = input.readBytes(buffer, 0, buffer.length);
				if (count <= 0)
					break;
				output.writeBytes(buffer, 0, count);
				mutex.acquire();
				copiedBytes += count;
				mutex.release();
			}
		}
		catch (_:Eof) {}
		catch (error:Dynamic) failure = error;
		try input.close() catch (_:Dynamic) {}
		try output.close() catch (_:Dynamic) {}
		if (failure != null)
			throw failure;
	}

	function complete(success:Bool):Void
	{
		mutex.acquire();
		phase = success ? COMPLETE : FAILED;
		finished = true;
		succeeded = success;
		currentFile = '';
		if (success)
			copiedBytes = totalBytes;
		mutex.release();
	}
}
#end
