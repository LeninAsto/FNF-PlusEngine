package objects;

import flixel.graphics.frames.FlxAtlasFrames;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';
	
	// Sistema de íconos animados (Codename Engine style)
	public var isAnimated:Bool = false;
	public var animFPS:Int = 24; // FPS por defecto para animaciones

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true, ?forceAnimated:Bool = false) {
		if(this.char != char) {
			try {
				var name:String = 'icons/' + char;
				if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
				if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
				
				// Detectar si es un ícono animado (buscar XML)
				var xmlPath:String = name + '.xml';
				isAnimated = forceAnimated || Paths.fileExists('images/' + xmlPath, TEXT);
				
				if(isAnimated) {
					// Cargar ícono animado con frames XML
					var atlas:FlxAtlasFrames = null;
					try {
						atlas = Paths.getSparrowAtlas(name.substring(6)); // Remover 'icons/' del path
					} catch(e:Dynamic) {
						trace('Error loading animated icon atlas for $char: $e');
						atlas = null;
					}
					
				if(atlas != null && atlas.frames != null && atlas.frames.length > 0) {
					frames = atlas;
					// Buscar animaciones disponibles manualmente
					var hasNormalAnim:Bool = false;
					var hasLosingAnim:Bool = false;
					
					for(frame in frames.frames) {
						if(frame.name.startsWith('normal')) hasNormalAnim = true;
						if(frame.name.startsWith('losing')) hasLosingAnim = true;
						if(hasNormalAnim && hasLosingAnim) break; // Optimización: salir si ya encontramos ambas
					}
					if(hasNormalAnim) {
						animation.addByPrefix('normal', 'normal', animFPS, true, isPlayer);
						if(hasLosingAnim) {
							animation.addByPrefix('losing', 'losing', animFPS, true, isPlayer);
						}
						animation.play('normal');
					} else {
						// Fallback: usar todas las frames como animación única
						animation.addByPrefix(char, '', animFPS, true, isPlayer);
						animation.play(char);
					}
					
					// Calcular offsets para íconos animados
					if(animation.curAnim != null && animation.curAnim.numFrames > 0) {
						var firstFrameData = frames.frames[0];
						if(firstFrameData != null && firstFrameData.frame != null) {
							iconOffsets[0] = (firstFrameData.frame.width - 150) / 2;
							iconOffsets[1] = (firstFrameData.frame.height - 150) / 2;
						} else {
							iconOffsets[0] = iconOffsets[1] = 0;
						}
					} else {
						iconOffsets[0] = iconOffsets[1] = 0;
					}
				} else {
					// Si no se pudo cargar el XML o está vacío, usar método estático
					isAnimated = false;
					loadStaticIcon(name, allowGPU);
				}
			} else {
				// Cargar ícono estático normal
				loadStaticIcon(name, allowGPU);
			}
			
			updateHitbox();
			this.char = char;

			if(char.endsWith('-pixel'))
				antialiasing = false;
			else
				antialiasing = ClientPrefs.data.antialiasing;
			} catch(e:Dynamic) {
				trace('CRITICAL ERROR loading icon for $char: $e');
				// Fallback a icono por defecto
				var defaultName:String = 'icons/icon-face';
				if(Paths.fileExists('images/' + defaultName + '.png', IMAGE)) {
					try {
						isAnimated = false;
						loadStaticIcon(defaultName, allowGPU);
						updateHitbox();
						this.char = char;
					} catch(e2:Dynamic) {
						trace('ERROR: Could not load fallback icon either: $e2');
					}
				}
			}
		}
	}
	
	// Función auxiliar para cargar íconos estáticos
	private function loadStaticIcon(name:String, allowGPU:Bool = true):Void {
		var graphic = Paths.image(name, allowGPU);
		if(graphic == null) {
			trace('ERROR: Could not load graphic for icon: $name');
			return;
		}
		
		var iSize:Float = 1.0;
		if(graphic.width > 0 && graphic.height > 0) {
			iSize = Math.round(graphic.width / graphic.height);
			if(iSize <= 0) iSize = 1.0;
		}
		
		loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
		
		if(width > 0 && height > 0) {
			iconOffsets[0] = (width - 150) / iSize;
			iconOffsets[1] = (height - 150) / iSize;
		} else {
			iconOffsets[0] = iconOffsets[1] = 0;
		}
		
		if(frames != null && frames.frames != null && frames.frames.length > 0) {
			animation.add(char, [for(i in 0...frames.frames.length) i], 0, false, isPlayer);
			animation.play(char);
		}
	}
	
	/**
	 * Cambia la animación del ícono (solo para íconos animados)
	 * @param animName Nombre de la animación ('normal' o 'losing')
	 */
	public function playAnim(animName:String):Void {
		if(!isAnimated || animation.getByName(animName) == null) return;
		animation.play(animName);
	}
	
	/**
	 * Actualiza la animación del ícono según el porcentaje de salud
	 * @param healthPercent Porcentaje de salud (0.0 a 1.0)
	 */
	public function updateIconState(healthPercent:Float):Void {
		if(!isAnimated) return;
		
		// Cambiar entre 'normal' y 'losing' según la salud
		if(animation.getByName('losing') != null) {
			if(healthPercent < 0.2) {
				if(animation.curAnim == null || animation.curAnim.name != 'losing')
					playAnim('losing');
			} else {
				if(animation.curAnim == null || animation.curAnim.name != 'normal')
					playAnim('normal');
			}
		}
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		super.updateHitbox();
		if(autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}

	public function getCharacter():String {
		return char;
	}
}
