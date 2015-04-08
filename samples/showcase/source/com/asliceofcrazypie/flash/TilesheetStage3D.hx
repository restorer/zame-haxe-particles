package com.asliceofcrazypie.flash;

import openfl.display.BitmapData;
import openfl.display.Tilesheet;
import openfl.events.Event;

#if flash11
import flash.Vector;
import haxe.Timer;
import flash.errors.Error;
import flash.utils.Endian;
import flash.display3D.Context3D;
import flash.display3D.Context3DRenderMode;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.textures.Texture;
import flash.display3D.VertexBuffer3D;
import flash.display.Stage;
import flash.display.Graphics;
import flash.errors.ArgumentError;
import flash.utils.ByteArray;
import flash.events.ErrorEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
#end

/**
 * ...
 * @author Paul M Pepper
 */
class TilesheetStage3D extends Tilesheet
{
	public function new( inImage:BitmapData, premultipliedAlpha:Bool = true )
	{
		#if flash11
		inImage = TilesheetStage3D.fixTextureSize( inImage.clone(), true );
		#end

		super( inImage );

		#if flash11
		this.premultipliedAlpha = premultipliedAlpha;
		fallbackMode = FallbackMode.ALLOW_FALLBACK;

		if ( !_isInited && !Type.enumEq( fallbackMode, FallbackMode.NO_FALLBACK ) )
		{
			throw new Error( 'Attemping to create TilesheetStage3D object before Stage3D has initialised.' );
		}

		if ( context != null && context.context3D != null )
		{
			onResetTexture( null );
			context.addEventListener( ContextWrapper.RESET_TEXTURE, onResetTexture );
		}
		#end
	}

	#if flash11
	private function onResetTexture(e:Event):Void
	{
		texture = context.uploadTexture( __bitmap );
	}

	public var premultipliedAlpha(default, null):Bool;

	private var texture:Texture;

	//static vars
	private static var context:ContextWrapper;
	private static var _isInited:Bool;

	//config
	public var fallbackMode:FallbackMode;

	//internal
	private static var _stage:Stage;
	private static var _stage3DLevel:Int;
	private static var _initCallback:String->Void;
	public static inline var MAX_VERTEX_PER_BUFFER:Int = 65532;
	public static inline var MAX_INDICES_PER_BUFFER:Int = 98298;

	public static var indices:ByteArray;

	public static function init( stage:Stage, stage3DLevel:Int = 0, antiAliasLevel:Int = 5, initCallback:String->Void = null, renderMode:Context3DRenderMode = null ):Void
	{
		if ( !_isInited )
		{
			if ( stage3DLevel < 0 || stage3DLevel >= Std.int( stage.stage3Ds.length ) )
			{
				throw new ArgumentError( 'stage3D depth of '+stage3DLevel+' out of bounds 0-'+(stage.stage3Ds.length-1) );
			}

			antiAliasing = antiAliasLevel;

			_isInited = true;

			context = new ContextWrapper( stage3DLevel );

			indices = new ByteArray();
			indices.endian = Endian.LITTLE_ENDIAN;

			for ( i in 0...Std.int( ( MAX_VERTEX_PER_BUFFER / 4 ) ) )
			{
				indices.writeShort( (i * 4) + 2 );
				indices.writeShort( (i*4) + 1 );
				indices.writeShort( (i * 4) + 0 );
				indices.writeShort( (i * 4) + 3 );
				indices.writeShort( (i * 4) + 2 );
				indices.writeShort( (i * 4) + 0 );
			}

			_stage = stage;
			_stage3DLevel = stage3DLevel;
			_initCallback = initCallback;

			context.init( stage, onContextInit, renderMode );
		}
	}

	private static function onContextInit():Void
	{
		if ( _initCallback != null )
		{
			//really not sure why this delay is needed
			Timer.delay( function(){
			_initCallback( context.context3D == null ? 'failure' : 'success' );
			_initCallback = null;
			},
			50);
		}
	}

	public static inline function clearGraphic( graphic:Graphics ):Void
	{
		if ( context != null )
		{
			context.clearGraphic( graphic );
		}
	}

	override public function drawTiles(graphics:Graphics, tileData:Array<Float>, smooth:Bool = false, flags:Int = 0,count:Int = -1):Void
	{
		if ( context != null && context.context3D != null && !Type.enumEq( fallbackMode, FallbackMode.FORCE_FALLBACK ) )
		{
			//parse flags
			var isMatrix:Bool = (flags & Tilesheet.TILE_TRANS_2x2) > 0;
			var isScale:Bool = (flags & Tilesheet.TILE_SCALE) > 0;
			var isRotation:Bool = (flags & Tilesheet.TILE_ROTATION) > 0;
			var isRGB:Bool = (flags & Tilesheet.TILE_RGB) > 0;
			var isAlpha:Bool = (flags & Tilesheet.TILE_ALPHA) > 0;
			var isBlendAdd:Bool = (flags & Tilesheet.TILE_BLEND_ADD) > 0;
			var isBlendMultiply:Bool = (flags & Tilesheet.TILE_BLEND_MULTIPLY) > 0;
			var isBlendScreen:Bool = (flags & Tilesheet.TILE_BLEND_SCREEN) > 0;
			var isRect:Bool = (flags & Tilesheet.TILE_RECT) > 0;
			var isOrigin:Bool = (flags & Tilesheet.TILE_ORIGIN) > 0;

			var scale:Float = 1;
			var rotation:Float = 0;
			var cosRotation:Float = Math.cos( rotation );
			var sinRotation:Float = Math.sin( rotation );
			var r:Float = 1;
			var g:Float = 1;
			var b:Float = 1;
			var a:Float = 1;

			var rect:Rectangle;
			var origin:Point;

			//determine data structure based on flags
			var tileDataPerItem:Int = 3;
			var dataPerVertice:Int = 5;

			var xOff:Int = 0;
			var yOff:Int = 1;
			var tileIdOff:Int = 2;
			var scaleOff:Int = 0;
			var rotationOff:Int = 0;
			var matrixOff:Int = 0;
			var matrixPos:Int = 0;
			var rOff:Int = 0;
			var gOff:Int = 0;
			var bOff:Int = 0;
			var aOff:Int = 0;

			if (isRect) { tileDataPerItem = isOrigin ? 8 : 6; }

			if (isMatrix)
			{
				matrixOff = tileDataPerItem; tileDataPerItem += 4;
			}
			else
			{
				if (isScale) { scaleOff = tileDataPerItem; tileDataPerItem++; }
				if (isRotation) { rotationOff = tileDataPerItem; tileDataPerItem++; }
			}

			if (isRGB)
			{
				rOff = tileDataPerItem;
				gOff = tileDataPerItem + 1;
				bOff = tileDataPerItem + 2;
				tileDataPerItem += 3;
				dataPerVertice += 3;
			}
			if (isAlpha)
			{
				aOff = tileDataPerItem;
				tileDataPerItem++;
				dataPerVertice++;
			}

			var totalCount = count;

			if (count < 0) {

				totalCount = tileData.length;

			}

			var numItems:Int = Std.int( totalCount / tileDataPerItem );

			if ( numItems == 0 )
			{
				return;
			}

			if ( totalCount % tileDataPerItem != 0 )
			{
				throw new ArgumentError( 'tileData length must be a multiple of '+tileDataPerItem );
			}

			//vertex data
			var vertexPerItem:Int = 4;
			var numVertices:Int = numItems * vertexPerItem;

			var renderJob:RenderJob;

			var tileDataPos:Int = 0;
			var vertexPos:Int = 0;

			var transform_tx:Float, transform_ty:Float, transform_a:Float, transform_b:Float, transform_c:Float, transform_d:Float;

			///////////////////
			// for each item //
			///////////////////
			var maxNumItems:Int = 16383;
			var startItemPos:Int = 0;
			var numItemsThisLoop:Int = 0;

			var spriteSortItem:SpriteSortItem = context.getSpriteSortItem( graphics );

			while ( tileDataPos < totalCount )
			{
				numItemsThisLoop = numItems > maxNumItems ? maxNumItems : numItems;
				numItems -= numItemsThisLoop;

				renderJob = RenderJob.getJob();
				renderJob.texture = texture;
				renderJob.isRGB = isRGB;
				renderJob.isAlpha = isAlpha;
				renderJob.isSmooth = smooth;
				renderJob.dataPerVertice = dataPerVertice;
				renderJob.numVertices = numItemsThisLoop * vertexPerItem;
				renderJob.premultipliedAlpha = this.premultipliedAlpha;

				if (isBlendAdd)
				{
					renderJob.blendMode = RenderJob.BLEND_ADD;
				}
				else if (isBlendMultiply)
				{
					renderJob.blendMode = RenderJob.BLEND_MULTIPLY;
				}
				else if (isBlendScreen)
				{
					renderJob.blendMode = RenderJob.BLEND_SCREEN;
				}
				else
				{
					renderJob.blendMode = RenderJob.BLEND_NORMAL;
				}

				vertexPos = 0;

				for( i in 0...numItemsThisLoop )
				{
					rect = null;
					origin = null;

					if (isRect)
					{
						rect = __rectTile;
						origin = __point;

						rect.setTo(	tileData[tileDataPos + 2],
									tileData[tileDataPos + 3],
									tileData[tileDataPos + 4],
									tileData[tileDataPos + 5]);

						if (isOrigin)
						{
							origin.setTo(	tileData[tileDataPos + 6] / rect.width,
											tileData[tileDataPos + 7] / rect.height);
						}
						else
						{
							origin.setTo(0, 0);
						}
					}

					//calculate transforms
					transform_tx = tileData[tileDataPos + xOff];
					transform_ty = tileData[tileDataPos + yOff];

					if ( isMatrix )
					{
						matrixPos = tileDataPos + matrixOff;
						transform_a = tileData[matrixPos++];
						transform_b = tileData[matrixPos++];
						transform_c = tileData[matrixPos++];
						transform_d = tileData[matrixPos++];
					}
					else
					{
						if ( isScale )
						{
							scale = tileData[tileDataPos+scaleOff];
						}

						if ( isRotation )
						{
							rotation = -tileData[tileDataPos + rotationOff];
							cosRotation = Math.cos( rotation );
							sinRotation = Math.sin( rotation );
						}

						transform_a = scale * cosRotation;
						transform_c = scale * -sinRotation;
						transform_b = scale * sinRotation;
						transform_d = scale * cosRotation;
					}

					if ( isRGB )
					{
						r = tileData[tileDataPos + rOff];
						g = tileData[tileDataPos + gOff];
						b = tileData[tileDataPos + bOff];
					}

					if ( isAlpha )
					{
						a = tileData[tileDataPos + aOff];
					}

					setVertexData(
						Std.int( tileData[tileDataPos + tileIdOff] ),
						transform_tx,
						transform_ty,
						transform_a,
						transform_b,
						transform_c,
						transform_d,
						isRGB,
						isAlpha,
						r,
						g,
						b,
						a,
						renderJob.vertices,
						vertexPos,
						context.getNextDepth(),
						rect,
						origin
					);

					tileDataPos += tileDataPerItem;
					vertexPos += vertexPerItem * dataPerVertice;
				}

				//push vertices into jobs list
				spriteSortItem.addJob( renderJob );
			}//end while
		}
		else if( !Type.enumEq( fallbackMode, FallbackMode.NO_FALLBACK ) )
		{
			super.drawTiles(graphics, tileData, smooth, flags,count);
		}
	}


	private inline function setVertexData(tileId:Int, transform_tx:Float, transform_ty:Float, transform_a:Float, transform_b:Float, transform_c:Float, transform_d:Float, isRGB:Bool, isAlpha:Bool, r:Float, g:Float, b:Float, a:Float, vertices:Vector<Float>, vertexPos:Int, depth:Float, rect:Rectangle = null, origin:Point = null ):Void
	{
		var c:Point = origin;
		var tile:Rectangle = rect;
		var uv:Rectangle = __rectUV;

		if (tile == null)
		{
			c = __centerPoints[tileId];
			uv = __tileUVs[tileId];
			tile = __tileRects[tileId];
		}
		else
		{
			uv.setTo(tile.left / __bitmapWidth, tile.top / __bitmapHeight, tile.right / __bitmapWidth, tile.bottom / __bitmapHeight);
		}

		var imgWidth:Int = Std.int( tile.width );
		var imgHeight:Int = Std.int( tile.height );

		var centerX:Float = c.x * imgWidth;
		var centerY:Float = c.y * imgHeight;

		var px:Float;
		var py:Float;

		//top left
		px = -centerX;
		py = -centerY;

		var off:Int = 0;

		vertices[vertexPos++] = ( px * transform_a + py * transform_c + transform_tx );//top left x
		vertices[vertexPos++] = ( px * transform_b + py * transform_d + transform_ty );//top left y
		vertices[vertexPos++] = ( depth );//top left z

		vertices[vertexPos++] = ( uv.x );//top left u
		vertices[vertexPos++] = ( uv.y );//top left v

		if ( isRGB )
		{
			vertices[vertexPos++] = ( r );
			vertices[vertexPos++] = ( g );
			vertices[vertexPos++] = ( b );
		}

		if ( isAlpha )
		{
			vertices[vertexPos++] = ( a );
		}

		//top right
		px = imgWidth-centerX;
		py = -centerY;

		vertices[vertexPos++] = ( px * transform_a + py * transform_c + transform_tx );//top right x
		vertices[vertexPos++] = ( px * transform_b + py * transform_d + transform_ty );//top right y
		vertices[vertexPos++] = ( depth );//top right z

		vertices[vertexPos++] = ( uv.width );//top right u
		vertices[vertexPos++] = ( uv.y );//top right v

		if ( isRGB )
		{
			vertices[vertexPos++] = ( r );
			vertices[vertexPos++] = ( g );
			vertices[vertexPos++] = ( b );
		}

		if ( isAlpha )
		{
			vertices[vertexPos++] = ( a );
		}

		//bottom right
		px = imgWidth-centerX;
		py = imgHeight-centerY;

		vertices[vertexPos++] = ( px * transform_a + py * transform_c + transform_tx );//bottom right x
		vertices[vertexPos++] = ( px * transform_b + py * transform_d + transform_ty );//bottom right y
		vertices[vertexPos++] = ( depth );//bottom right z

		vertices[vertexPos++] = ( uv.width );//bottom right u
		vertices[vertexPos++] = ( uv.height );//bottom right v

		if ( isRGB )
		{
			vertices[vertexPos++] = ( r );
			vertices[vertexPos++] = ( g );
			vertices[vertexPos++] = ( b );
		}

		if ( isAlpha )
		{
			vertices[vertexPos++] = ( a );
		}

		//bottom left
		px = -centerX;
		py = imgHeight-centerY;

		vertices[vertexPos++] = ( px * transform_a + py * transform_c + transform_tx );//bottom left x
		vertices[vertexPos++] = ( px * transform_b + py * transform_d + transform_ty );//bottom left y
		vertices[vertexPos++] = ( depth );//bottom left z

		vertices[vertexPos++] = ( uv.x );//bottom left u
		vertices[vertexPos++] = ( uv.height );//bottom left v

		if ( isRGB )
		{
			vertices[vertexPos++] = ( r );
			vertices[vertexPos++] = ( g );
			vertices[vertexPos++] = ( b );
		}

		if ( isAlpha )
		{
			vertices[vertexPos++] = ( a );
		}
	}

	public static var antiAliasing(default,set):Int;

	private static inline function set_antiAliasing( value:Int ):Int
	{
		antiAliasing = value > 0 ? value < 16 ? value : 16 : 0;//limit value to 0-16

		if ( context != null && context.context3D != null )
		{
			context.onStageResize( null );
		}

		return antiAliasing;
	}

	public static var driverInfo(get, never):String;

	private static function get_driverInfo():String
	{
		if ( context != null && context.context3D != null)
		{
			return context.context3D.driverInfo;
		}

		return '';
	}

	public function dispose():Void
	{
		this.fallbackMode = null;

		if ( this.texture != null )
		{
			this.texture.dispose();
			this.texture = null;
		}

		if ( this.__bitmap != null )
		{
			this.__bitmap.dispose();
			this.__bitmap = null;
		}
	}

	//helper methods
	public static inline function roundUpToPow2( number:Int ):Int
	{
		number--;
		number |= number >> 1;
		number |= number >> 2;
		number |= number >> 4;
		number |= number >> 8;
		number |= number >> 16;
		number++;
		return number;
	}

	public static inline function isTextureOk( texture:BitmapData ):Bool
	{
		return ( roundUpToPow2( texture.width ) == texture.width ) && ( roundUpToPow2( texture.height ) == texture.height );
	}

	public static inline function fixTextureSize( texture:BitmapData, autoDispose:Bool = false ):BitmapData
	{
		return if ( isTextureOk( texture ) )
		{
			texture;
		}
		else
		{
			var newTexture:BitmapData = new BitmapData( roundUpToPow2( texture.width ), roundUpToPow2( texture.height ), true, 0 );

			newTexture.copyPixels( texture, texture.rect, new Point(), null, null, true );

			if (autoDispose)
			{
				texture.dispose();
			}

			newTexture;
		}
	}
	#end
}

#if flash11
enum FallbackMode
{
	NO_FALLBACK;
	ALLOW_FALLBACK;
	FORCE_FALLBACK;
}
#end