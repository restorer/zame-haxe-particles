package com.asliceofcrazypie.flash;

#if flash11
import flash.display3D.Context3D;
import flash.display3D.Program3D;
import flash.display3D.textures.Texture;
import flash.Vector;
import flash.Vector;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.utils.ByteArray;
import flash.display3D.Context3DRenderMode;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.utils.Endian;

/**
 * ...
 * @author Paul M Pepper
 */
class ContextWrapper extends EventDispatcher
{
	public static inline var RESET_TEXTURE:String = 'resetTexture';

	public var presented:Bool;
	public var context3D:Context3D;
	public var depth(default, null):Int;

	private var stage:Stage;
	private var antiAliasLevel:Int;
	private var baseTransformMatrix:Matrix3D;

	public var programRGBASmooth:Program3D;
	public var programRGBSmooth:Program3D;
	public var programASmooth:Program3D;
	public var programSmooth:Program3D;
	public var programRGBA:Program3D;
	public var programRGB:Program3D;
	public var programA:Program3D;
	public var program:Program3D;

	private var vertexDataRGBA:ByteArray;
	private var vertexData:ByteArray;

	private var fragmentDataRGBASmooth:ByteArray;
	private var fragmentDataRGBSmooth:ByteArray;
	private var fragmentDataASmooth:ByteArray;
	private var fragmentDataSmooth:ByteArray;
	private var fragmentDataRGBA:ByteArray;
	private var fragmentDataRGB:ByteArray;
	private var fragmentDataA:ByteArray;
	private var fragmentData:ByteArray;

	private static inline var INIT_DEPTH:Float = 0.9999999;
	private static inline var MIN_DEPTH_STEP:Float = 0.0000001;

	private var currentDepth:Float;

	private var _initCallback:Void->Void;

	//graphic to sprite lookup table
	private var graphicCache:Map<Graphics,Sprite>;
	private var spriteSortItemCache:Map<Sprite,SpriteSortItem>;
	private var currentSpriteSortItems:Vector<SpriteSortItem>;

	//avoid unneeded context changes
	private var currentTexture:Texture;
	private var currentProgram:Program3D;


	public function new( depth:Int, antiAliasLevel:Int = 1 )
	{
		super();

		this.depth = depth;
		this.antiAliasLevel = antiAliasLevel;
		currentDepth = INIT_DEPTH;

		//vertex shader data
		var vertexRawDataRGBA:Array<Int> = 	[ -96, 1, 0, 0, 0, -95, 0, 24, 0, 0, 0, 0, 0, 15, 3, 0, 0, 0, -28, 0, 0, 0, 0, 0, 0, 0, -28, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 4, 1, 0, 0, -28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 15, 4, 2, 0, 0, -28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var vertexRawData:Array<Int> = 		[ -96, 1, 0, 0, 0, -95, 0, 24, 0, 0, 0, 0, 0, 15, 3, 0, 0, 0, -28, 0, 0, 0, 0, 0, 0, 0, -28, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 4, 1, 0, 0, -28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

		//fragment shaders
		var fragmentRawDataRGBASmooth:Array<Int> = 	[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 16, 3, 0, 0, 0, 2, 0, 15, 2, 1, 0, 0, -28, 2, 0, 0, 0, 1, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 2, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawDataRGBSmooth:Array<Int> = 	[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 16, 3, 0, 0, 0, 1, 0, 15, 2, 1, 0, 0, -28, 2, 0, 0, 0, 1, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 1, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawDataASmooth:Array<Int> = 	[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 16, 3, 0, 0, 0, 1, 0, 8, 2, 1, 0, 0, -1, 2, 0, 0, 0, 1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 1, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawDataSmooth:Array<Int> = 		[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 16, 0, 0, 0, 0, 0, 0, 15, 3, 1, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawDataRGBA:Array<Int> = 		[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 3, 0, 0, 0, 2, 0, 15, 2, 1, 0, 0, -28, 2, 0, 0, 0, 1, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 2, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawDataRGB:Array<Int> = 		[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 3, 0, 0, 0, 2, 0, 15, 2, 1, 0, 0, -28, 2, 0, 0, 0, 1, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 2, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawDataA:Array<Int> = 			[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 3, 0, 0, 0, 1, 0, 8, 2, 1, 0, 0, -1, 2, 0, 0, 0, 1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 1, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawData:Array<Int> = 			[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 1, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

		vertexDataRGBA = 	rawDataToBytes( vertexRawDataRGBA );
		vertexData = 		rawDataToBytes( vertexRawData );

		fragmentDataRGBASmooth = 	rawDataToBytes( fragmentRawDataRGBASmooth );
		fragmentDataRGBSmooth = 	rawDataToBytes( fragmentRawDataRGBSmooth );
		fragmentDataASmooth = 		rawDataToBytes( fragmentRawDataASmooth );
		fragmentDataSmooth = 		rawDataToBytes( fragmentRawDataSmooth );
		fragmentDataRGBA = 			rawDataToBytes( fragmentRawDataRGBA );
		fragmentDataRGB = 			rawDataToBytes( fragmentRawDataRGB );
		fragmentDataA = 			rawDataToBytes( fragmentRawDataA );
		fragmentData = 				rawDataToBytes( fragmentRawData );

		graphicCache = new Map<Graphics,Sprite>();
		spriteSortItemCache = new Map<Sprite,SpriteSortItem>();
		currentSpriteSortItems = new Vector<SpriteSortItem>();
	}

	public inline function setTexture( texture:Texture ):Void
	{
		if ( context3D != null )
		{

			if ( texture != currentTexture )
			{
				context3D.setTextureAt( 0, texture );
				currentTexture = texture;
			}
		}
	}

	public inline function getNextDepth():Float
	{
		var depth:Float = currentDepth;
		currentDepth -= MIN_DEPTH_STEP;

		return depth;
	}

	public inline function init( stage:Stage, initCallback:Void->Void = null, renderMode:Context3DRenderMode ):Void
	{
		if ( context3D == null )
		{
			if ( renderMode == null )
			{
				renderMode = Context3DRenderMode.AUTO;
			}

			this.stage = stage;
			this._initCallback = initCallback;
			stage.stage3Ds[depth].addEventListener( Event.CONTEXT3D_CREATE, initStage3D );
			stage.stage3Ds[depth].addEventListener(ErrorEvent.ERROR, initStage3DError );
			stage.stage3Ds[depth].requestContext3D( #if (haxe_ver < 3.2) Std.string( renderMode ) #else renderMode #end );

			stage.addEventListener(Event.EXIT_FRAME, onRender, false, -0xFFFFFE );
		}
		else
		{
			if ( initCallback != null )
			{
				initCallback();
			}
		}
	}

	private function onRender(e:Event):Void
	{
		if ( context3D != null && !presented )
		{
			if ( currentSpriteSortItems.length > 0 )
			{
				SpriteSortItem.sortItems( currentSpriteSortItems );

				var rendered:Int = 0;

				for ( spriteSortItem in currentSpriteSortItems )
				{
					rendered += spriteSortItem.renderBuffers( this );
				}

				if ( rendered > 0 )
				{
					presented = true;
					context3D.present();
				}
			}
		}
	}

	private function initStage3D(e:Event):Void
	{
		if ( context3D != null )
		{
			if (stage.stage3Ds[depth].context3D != context3D)
			{
				context3D = null;//this context has been lost, get new context
			}
		}

		if ( context3D == null )
		{
			context3D = stage.stage3Ds[depth].context3D;

			if ( context3D != null )
			{
				context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);

				baseTransformMatrix = new Matrix3D();

				stage.addEventListener(Event.RESIZE, onStageResize );//listen for future stage resize events

				//init programs
				programRGBASmooth = context3D.createProgram();
				programRGBASmooth.upload( vertexDataRGBA, fragmentDataRGBASmooth);

				programRGBSmooth = context3D.createProgram();
				programRGBSmooth.upload( vertexDataRGBA, fragmentDataRGBSmooth);

				programASmooth = context3D.createProgram();
				programASmooth.upload( vertexDataRGBA, fragmentDataASmooth);

				programSmooth = context3D.createProgram();
				programSmooth.upload( vertexData, fragmentDataSmooth);

				programRGBA = context3D.createProgram();
				programRGBA.upload( vertexDataRGBA, fragmentDataRGBA);

				programRGB = context3D.createProgram();
				programRGB.upload( vertexDataRGBA, fragmentDataRGB);

				programA = context3D.createProgram();
				programA.upload( vertexDataRGBA, fragmentDataA);

				program = context3D.createProgram();
				program.upload( vertexData, fragmentData);

				onStageResize(null);//init the base transform matrix

				clear();

				//upload textures
				dispatchEvent( new Event( RESET_TEXTURE ) );
			}
		}

		if ( this._initCallback != null )
		{
			this._initCallback();
			this._initCallback = null;//only call once
		}
	}

	private function initStage3DError(e:Event):Void
	{
		if ( this._initCallback != null )
		{
			this._initCallback();
			this._initCallback = null;//only call once
		}
	}

	public function onStageResize(e:Event):Void
	{
		if ( context3D != null )
		{
			context3D.configureBackBuffer(stage.stageWidth, stage.stageHeight, TilesheetStage3D.antiAliasing, false);

			baseTransformMatrix.identity();
			baseTransformMatrix.appendTranslation( -stage.stageWidth * 0.5, -stage.stageHeight * 0.5, 0 );
			baseTransformMatrix.appendScale( 2 / stage.stageWidth, -2 / stage.stageHeight, 1 );

			//apply the transform matrix
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, baseTransformMatrix, true);
		}
	}

	public inline function clearGraphic( graphic:Graphics ):Void
	{
		var sprite:Sprite = findSpriteByGraphicCached( stage, graphic );

		if ( sprite != null )
		{
			var spriteSortItem:SpriteSortItem = getSpriteSortItemBySprite( sprite );

			if ( spriteSortItem != null )
			{
				if ( spriteSortItem.clearJobs() > 0 )
				{
					presented = false;

					clear();
				}
			}
		}
	}

	private inline function clear():Void
	{
		currentDepth = INIT_DEPTH;

		if ( context3D != null )
		{
			context3D.clear( 0, 0, 0, 1 );
			presented = false;
		}
	}

	public function uploadTexture(image:BitmapData) : Texture
	{
		if ( context3D != null )
		{
			var texture:Texture = context3D.createTexture(image.width, image.height, Context3DTextureFormat.BGRA, false);

			texture.uploadFromBitmapData(image);

			// generate mipmaps
			var currentWidth:Int = image.width;
			var currentHeight:Int = image.height;
			var level:Int = 1;
			var canvas:BitmapData = new BitmapData(currentWidth>>1, currentHeight>>1, true, 0);
			var transform:Matrix = new Matrix(.5, 0, 0, .5);

			while ( currentWidth >= 2 && currentHeight >= 2 )//should that be an OR?
			{
				currentWidth = currentWidth >> 1;
				currentHeight = currentHeight >> 1;
				canvas.fillRect(canvas.rect, 0);
				canvas.draw(image, transform, null, null, null, true);
				texture.uploadFromBitmapData(canvas, level++);
				transform.scale(0.5, 0.5);
			}

			canvas.dispose();

			return texture;
		}

		return null;
	}

	private inline function doSetProgram( program:Program3D ):Void
	{
		if ( context3D != null && program != currentProgram )
		{
			context3D.setProgram( program );
			currentProgram = program;
		}
	}

	public function setProgram(isRGB:Bool, isAlpha:Bool, smooth:Bool):Void
	{
		if ( smooth )
		{
			if ( isRGB && isAlpha )
			{
				doSetProgram( programRGBASmooth );
			}
			else if ( isRGB )
			{
				doSetProgram( programRGBSmooth );
			}
			else if ( isAlpha )
			{
				doSetProgram( programASmooth );
			}
			else
			{
				doSetProgram( programSmooth );
			}
		}
		else
		{
			if ( isRGB && isAlpha )
			{
				doSetProgram( programRGBA );
			}
			else if ( isRGB )
			{
				doSetProgram( programRGB );
			}
			else if ( isAlpha )
			{
				doSetProgram( programA );
			}
			else
			{
				doSetProgram( program );
			}
		}
	}


	public inline function getSpriteSortItem( graphic:Graphics ):SpriteSortItem
	{
		return getSpriteSortItemBySprite( findSpriteByGraphicCached( stage, graphic ) );
	}

	private inline function getSpriteSortItemBySprite( sprite:Sprite ):SpriteSortItem
	{
		return if ( sprite != null )
		{
			var found:SpriteSortItem = spriteSortItemCache.get( sprite );

			if ( found == null )
			{
				found = new SpriteSortItem( sprite );
				spriteSortItemCache.set( sprite, found );
				currentSpriteSortItems.push( found );
			}

			found;
		}
		else
		{
			null;
		}
	}

	private static inline function rawDataToBytes(rawData:Array<Int>):ByteArray
	{
		var bytes:ByteArray = new ByteArray();
		bytes.endian = Endian.LITTLE_ENDIAN;

		for ( n in rawData )
		{
			bytes.writeByte( n );
		}

		return bytes;
	}

	//graphic helper methods

	private inline function findSpriteByGraphicCached( start:DisplayObject, graphic:Graphics ):Sprite
	{
		var found:Sprite = null;

		found = graphicCache.get( graphic );

		if ( found == null )
		{
			found = findSpriteByGraphic( start, graphic );
		}

		if ( found != null )
		{
			found.addEventListener(Event.REMOVED_FROM_STAGE, removeFromCache );
			graphicCache.set( graphic, found );
		}

		return found;
	}

	private function removeFromCache(e:Event):Void
	{
		var target:Sprite = cast( e.target, Sprite );

		target.removeEventListener(Event.REMOVED_FROM_STAGE, removeFromCache);

		graphicCache.remove( target.graphics );
	}


	public inline function findSpriteByGraphic( start:DisplayObject, graphic:Graphics ):Sprite
	{
		var searchList:Array<DisplayObject> = [start];
		var searchNext:Array<DisplayObject> = [];
		var searchTemp:Array<DisplayObject> = null;
		var found:Sprite = null;

		var sprite:Sprite, container:DisplayObjectContainer, button:SimpleButton;

		while ( searchList.length > 0 && found == null )
		{
			for ( item in searchList )
			{
				if ( Std.is( item, Sprite ) )
				{
					sprite = cast( item, Sprite );

					if ( sprite.graphics == graphic )
					{
						found = sprite;
						break;
					}
				}

				if ( Std.is( item, DisplayObjectContainer ) )
				{
					container = cast( item, DisplayObjectContainer );

					for ( i in 0...container.numChildren )
					{
						searchNext.push( container.getChildAt( i ) );
					}
				}
				else if ( Std.is( item, SimpleButton ) )
				{
					button = cast( item, SimpleButton );

					if ( button.downState != null )
					{
						searchNext.push( button.downState );
					}
					if ( button.upState != null )
					{
						searchNext.push( button.upState );
					}
					if ( button.overState != null )
					{
						searchNext.push( button.overState );
					}
				}
			}

			if ( found == null )
			{
				searchTemp = searchList;
				searchList = searchNext;
				searchNext = searchTemp;

				clearArray( searchNext );
			}
		}

		return found;
	}

	//misc methods
	public static inline function clearArray<T>( array:Array<T> ):Void
	{
		#if (cpp||php)
           array.splice(0,array.length);
        #else
           untyped array.length = 0;
        #end
	}
}
#end