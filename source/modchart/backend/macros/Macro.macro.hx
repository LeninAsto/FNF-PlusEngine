package modchart.backend.macros;

import haxe.ds.StringMap;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassField;

class Macro {
	public static function includeFiles() {
		
		// Include all modchart files except adapters - using full package path
		Compiler.include('modchart', true, ['modchart.backend.standalone.adapters']);
		
		// Get the engine name
		var engineName = haxe.macro.Context.definedValue("FM_ENGINE");
		if (engineName == null) {
			Context.error("FM_ENGINE is not defined!", Context.currentPos());
		}
		
		var adapterPackage = "modchart.backend.standalone.adapters." + engineName.toLowerCase();
		
		// Include the specific adapter
		Compiler.include(adapterPackage);
	}

	// public static function buildFlxShader():Array<Field> {
	// 	final fields = Context.getBuildFields();
	// 	final pos = Context.currentPos();
	// 	fields.push({
	// 		name: "__fmIdx",
	// 		kind: FVar(macro :Null<Int>, macro null),
	// 		access: [APrivate],
	// 		pos: pos
	// 	});
	// 	return fields;
	// }

	public static function addModchartStorage():Array<Field> {
		final fields = Context.getBuildFields();
		final pos = Context.currentPos();

		for (f in fields) {
			if (f.name == 'set_visible') {
				switch (f.kind) {
					case FFun(fun):
						fun.expr = macro {
							visible = Value;
							_fmVisible = Value;

							return Value;
						};
					default:
						// do nothing
				}
			} else if (f.name == 'get_visible') {
				switch (f.kind) {
					case FFun(fun):
						fun.expr = macro {
							return _fmVisible;
						};
					default:
						// do nothing
				}
			}
		}

		// uses _z to prevent collisions with other classes
		final zField:Field = {
			name: "_z",
			access: [APublic],
			kind: FieldType.FVar(macro :Float, macro $v{0}),
			pos: pos
		};
		final visField:Field = {
			name: "_fmVisible",
			access: [APublic],
			kind: FieldType.FVar(macro :Null<Bool>, macro true),
			pos: pos
		};
		final extraField:Field = {
			name: "_fmExtra",
			access: [APublic],
			kind: FieldType.FVar(macro :Dynamic, macro {}),
			pos: pos
		};

		fields.push(zField);
		fields.push(visField);
		fields.push(extraField);

		return fields;
	}

	public static function buildFlxCamera():Array<Field> {
		var fields = Context.getBuildFields();

		// idk why when i dont change the general draw items pooling system, theres so much graphic issues (with colors and uvs)
		/*
			var newField:Field = {
				name: '__fmStartTrianglesBatch',
				pos: Context.currentPos(),
				access: [APrivate],
				kind: FFun({
					args: [
						{
							name: "graphic",
							type: macro :flixel.graphics.FlxGraphic
						},
						{
							name: "blend",
							type: macro :openfl.display.BlendMode
						},
						{
							name: "shader",
							type: macro :flixel.system.FlxAssets.FlxShader
						},
						{
							name: "antialiasing",
							type: macro :Bool,
							value: macro $v{false}
						}
					],
					expr: macro {
						return getNewDrawTrianglesItem(graphic, antialiasing, true, blend, true, shader);
					},
					ret: macro :flixel.graphics.tile.FlxDrawTrianglesItem
				})
			};
			fields.push(newField);
		 */

		//for (f in fields) {
		//	if (f.name == 'startTrianglesBatch') {
		//		switch (f.kind) {
		//			case FFun(fun):
		//				// we're just removing a if statement cuz causes some color issues
		//				fun.expr = macro {
		//					return getNewDrawTrianglesItem(graphic, smoothing, isColored, blend #if (flixel >= "5.2.0"), hasColorOffsets, shader #end);
		//				};
		//			default:
		//				// do nothing
		//		}
		//	}
		//}

		return fields;
	}

	public static function buildFlxDrawTrianglesItem():Array<Field> {
		var fields = Context.getBuildFields();
		var newField:Field = {
			name: 'addGradientTriangles',
			pos: Context.currentPos(),
			access: [APublic],
			kind: FieldType.FFun({
				args: [
					{
						name: 'vertices',
						type: macro :DrawData<Float>
					},
					{
						name: 'indices',
						type: macro :DrawData<Int>
					},
					{
						name: 'uvtData',
						type: macro :DrawData<Float>
					},
					{
						name: 'position',
						type: macro :FlxPoint,
						opt: true
					},
					{
						name: 'cameraBounds',
						type: macro :FlxRect,
						opt: true
					},
					{
						name: 'transforms',
						type: macro :haxe.ds.Vector<ColorTransform>,
						opt: true
					}
				],
				expr: macro {
					// hay glitches en el alpha de las holds
					// no es de aqui, ya llege a la conclusion de que no es dentro de aqui
					// otra cosa, el alpha que agarran es de los batchs anteriores (no estos)
					// tipo si yo pongo en el arrow renderer una alpha hardcodeadas, esa alpha se pone en las primeras holds
					if (position == null)
						position = point.set();

					if (cameraBounds == null)
						cameraBounds = rect.set(0, 0, FlxG.width, FlxG.height);

					var verticesLength:Int = vertices.length;
					var prevVerticesLength:Int = this.vertices.length;
					var numberOfVertices:Int = Std.int(verticesLength / 2);
					var prevIndicesLength:Int = this.indices.length;
					var prevUVTDataLength:Int = this.uvtData.length;
					var prevNumberOfVertices:Int = this.numVertices;
					var prevColorsPos:Int = colorsPosition;
					var prevColorsLength:Int = this.colors.length;

					var tempX:Float, tempY:Float;
					var i:Int = 0;
					var currentVertexPosition:Int = prevVerticesLength;

					while (i < verticesLength) {
						tempX = position.x + vertices[i];
						tempY = position.y + vertices[i + 1];

						this.vertices[currentVertexPosition++] = tempX;
						this.vertices[currentVertexPosition++] = tempY;

						if (i == 0) {
							bounds.set(tempX, tempY, 0, 0);
						} else {
							inflateBounds(bounds, tempX, tempY);
						}

						i = i + 2;
					}

					var indicesLength:Int = indices.length;
					if (!cameraBounds.overlaps(bounds)) {
						this.vertices.splice(this.vertices.length - verticesLength, verticesLength);
					} else {
						var uvtDataLength:Int = uvtData.length;
						for (i in 0...uvtDataLength) {
							this.uvtData[prevUVTDataLength + i] = uvtData[i];
						}

						for (i in 0...indicesLength) {
							this.indices[prevIndicesLength + i] = indices[i] + prevNumberOfVertices;
						}

						if (colored) {
							for (i in 0...numberOfVertices) {
								this.colors[prevColorsLength + i] = 0;
							}

							colorsPosition += numberOfVertices;
						}

						verticesPosition = verticesPosition + verticesLength;
						indicesPosition = indicesPosition + indicesLength;
					}

					position.putWeak();
					cameraBounds.putWeak();

					#if (flixel >= "5.2.0")
					for (_ in 0...indicesLength) {
						final possibleTransform = transforms[Math.floor(_ / indicesLength * transforms.length)];

						var alphaMultiplier = 1.;

						if (possibleTransform != null)
							alphaMultiplier = possibleTransform.alphaMultiplier;

						alphas.push(alphaMultiplier);
					}

					if (colored || hasColorOffsets) {
						if (colorMultipliers == null)
							colorMultipliers = [];

						if (colorOffsets == null)
							colorOffsets = [];

						for (_ in 0...indicesLength) {
							final transform = transforms[Math.floor(_ / indicesLength * transforms.length)];
							if (transform != null) {
								colorMultipliers.push(transform.redMultiplier);
								colorMultipliers.push(transform.greenMultiplier);
								colorMultipliers.push(transform.blueMultiplier);

								colorOffsets.push(transform.redOffset);
								colorOffsets.push(transform.greenOffset);
								colorOffsets.push(transform.blueOffset);
								colorOffsets.push(transform.alphaOffset);
							} else {
								colorMultipliers.push(1);
								colorMultipliers.push(1);
								colorMultipliers.push(1);

								colorOffsets.push(0);
								colorOffsets.push(0);
								colorOffsets.push(0);
								colorOffsets.push(0);
							}

							colorMultipliers.push(1);
						}
					}
					#end
				}
			}),
		};

		fields.push(newField);

		return fields;
	}
}
