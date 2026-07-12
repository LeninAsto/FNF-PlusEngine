package states.stages;

import backend.BaseStage;
import flixel.FlxSprite;
import sys.FileSystem;
import openfl.display.BitmapData;

#if mobile
import mobile.backend.StorageUtil;
#end

class NotITG extends BaseStage
{
	var bgSprite:FlxSprite;
	
	override function create()
	{
		// Establecer color de fondo negro por defecto
		camGame.bgColor = 0xFF000000;
		
		// Configurar zoom por defecto
		defaultCamZoom = 0.9;
		
		// Intentar cargar el background del chart de StepMania
		loadStepManiaBackground();
	}
	
	function loadStepManiaBackground():Void
	{
		#if sys
		var customPath = states.PlayState.customAudioPath;
		if (customPath == null || (!customPath.contains('/sm/') && !customPath.contains('sm/')))
			return;
			
		// customPath tiene formato: ./sm/nombredelmod/
		// Necesitamos determinar si es StepMania estándar o NotITG
		
		var bgPath:String = null;
		
		// Intentar cargar desde lua/bg.png primero (NotITG)
		var notitgBgPath = customPath + 'lua/bg.png';
		if (FileSystem.exists(notitgBgPath))
		{
			bgPath = notitgBgPath;
			trace('Loading NotITG background from: ' + bgPath);
		}
		else
		{
			// Buscar archivos *-bg.png (StepMania estándar)
			var files = FileSystem.readDirectory(customPath);
			for (file in files)
			{
				if (file.toLowerCase().endsWith('-bg.png'))
				{
					bgPath = customPath + file;
					trace('Loading StepMania background from: ' + bgPath);
					break;
				}
			}
		}
		
		// Si encontramos un background, cargarlo
		if (bgPath != null && FileSystem.exists(bgPath))
		{
			try
			{
				var bitmapData = openfl.display.BitmapData.fromFile(bgPath);
				if (bitmapData != null)
				{
					bgSprite = new FlxSprite();
					bgSprite.loadGraphic(bitmapData);
					bgSprite.antialiasing = true;
					
					// Escalar para cubrir toda la pantalla manteniendo aspecto
					var scaleX = FlxG.width / bgSprite.width;
					var scaleY = FlxG.height / bgSprite.height;
					var scale = Math.max(scaleX, scaleY);
					
					bgSprite.scale.set(scale, scale);
					bgSprite.updateHitbox();
					bgSprite.screenCenter();
					bgSprite.scrollFactor.set(0, 0);
					
					// Añadir a camHUD para que esté detrás de todo
					bgSprite.cameras = [PlayState.instance.camHUD];
					
					trace('Background loaded successfully: ${bgSprite.width}x${bgSprite.height}');
				}
				else
				{
					trace('Failed to load bitmap data from: ' + bgPath);
				}
			}
			catch (e:Dynamic)
			{
				trace('Error loading background: ' + e);
			}
		}
		else
		{
			trace('No background found for StepMania chart');
		}
		#end
	}
	
	override function createPost()
	{
		// Agregar el background al principio del stage para que esté detrás de todo
		if (bgSprite != null)
		{
			// Insertar al principio para que esté detrás de todo
			PlayState.instance.insert(0, bgSprite);
		}
		else
		{
			// Si no hay background, mantener fondo negro
			camGame.bgColor = 0xFF000000;
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}

