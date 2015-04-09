package com.asliceofcrazypie.flash;

#if flash11
import flash.display3D.IndexBuffer3D;
import flash.display3D.textures.Texture;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.VertexBuffer3D;
import flash.Vector;
import flash.errors.Error;
import haxe.ds.StringMap;

/**
 * ...
 * @author Paul M Pepper
 */
class RenderJob
{
	public var texture:Texture;
	public var vertices(default, null):Vector<Float>;
	public var isRGB:Bool;
	public var isAlpha:Bool;
	public var isSmooth:Bool;

	public var blendMode:String;
	public var premultipliedAlpha:Bool;

	public var dataPerVertice:Int;
	public var numVertices(default, set):Int;
	public var numIndices(default, null):Int;

	private static var renderJobPool:Array<RenderJob>;

	public static inline var NUM_JOBS_TO_POOL:Int = 25;

	public static inline var BLEND_NORMAL:String = "normal";
	public static inline var BLEND_ADD:String = "add";
	public static inline var BLEND_MULTIPLY:String = "multiply";
	public static inline var BLEND_SCREEN:String = "screen";

	private static var premultipliedBlendFactors:StringMap<Array<Context3DBlendFactor>>;
	private static var noPremultipliedBlendFactors:StringMap<Array<Context3DBlendFactor>>;

	public function new()
	{
		this.vertices = new Vector<Float>( TilesheetStage3D.MAX_VERTEX_PER_BUFFER >> 2 );
	}

	private inline function set_numVertices( n:Int ):Int
	{
		this.numVertices = n;

		this.numIndices = Std.int( (numVertices / 2) * 3 );

		return n;
	}

	public inline function render( context:ContextWrapper ):Void
	{
		if ( context.context3D.driverInfo != 'Disposed' )
		{
			//blend mode
			setBlending(context);

			context.setProgram(isRGB,isAlpha,isSmooth);//assign appropriate shader

			context.setTexture( texture );

			//actually create the buffers
			var vertexbuffer:VertexBuffer3D = null;
			var indexbuffer:IndexBuffer3D = null;

			// Create VertexBuffer3D. numVertices vertices, of dataPerVertice Numbers each
			vertexbuffer = context.context3D.createVertexBuffer(numVertices, dataPerVertice);

			// Upload VertexBuffer3D to GPU. Offset 0, numVertices vertices
			vertexbuffer.uploadFromVector( vertices, 0, numVertices );

			// Create IndexBuffer3D.
			indexbuffer = context.context3D.createIndexBuffer(numIndices);
			// Upload IndexBuffer3D to GPU.
			indexbuffer.uploadFromByteArray( TilesheetStage3D.indices, 0, 0, numIndices );

			// vertex position to attribute register 0
			context.context3D.setVertexBufferAt (0, vertexbuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			// UV to attribute register 1
			context.context3D.setVertexBufferAt(1, vertexbuffer, 3, Context3DVertexBufferFormat.FLOAT_2);

			if ( isRGB && isAlpha )
			{
				context.context3D.setVertexBufferAt(2, vertexbuffer, 5, Context3DVertexBufferFormat.FLOAT_4);//rgba data
			}
			else if ( isRGB )
			{
				context.context3D.setVertexBufferAt(2, vertexbuffer, 5, Context3DVertexBufferFormat.FLOAT_3);//rgb data
			}
			else if ( isAlpha )
			{
				context.context3D.setVertexBufferAt(2, vertexbuffer, 5, Context3DVertexBufferFormat.FLOAT_1);//a data
			}
			else
			{
				context.context3D.setVertexBufferAt(2, null, 5);
			}

			context.context3D.drawTriangles( indexbuffer );
		}
	}

	public static inline function getJob():RenderJob
	{
		return renderJobPool.length > 0 ? renderJobPool.pop() : new RenderJob();
	}

	public static inline function returnJob( renderJob:RenderJob ):Void
	{
		if ( renderJobPool.length < NUM_JOBS_TO_POOL )
		{
			renderJobPool.push( renderJob );
		}
	}

	private inline function setBlending(context:ContextWrapper):Void
	{
		var factors = RenderJob.premultipliedBlendFactors;
		if (!premultipliedAlpha)
		{
			factors = RenderJob.noPremultipliedBlendFactors;
		}

		var factor:Array<Context3DBlendFactor> = factors.get(blendMode);
		if (factor == null)
		{
			factor = factors.get(RenderJob.BLEND_NORMAL);
		}

		context.context3D.setBlendFactors(factor[0], factor[1]);
	}

	public static function __init__():Void
	{
		renderJobPool = [];
		for ( i in 0...NUM_JOBS_TO_POOL )
		{
			renderJobPool.push( new RenderJob() );
		}

		RenderJob.initBlendFactors();
	}

	private static function initBlendFactors():Void
	{
		if (RenderJob.premultipliedBlendFactors == null)
		{
			RenderJob.premultipliedBlendFactors = new StringMap();
			RenderJob.premultipliedBlendFactors.set(BLEND_NORMAL, [Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA]);
			RenderJob.premultipliedBlendFactors.set(BLEND_ADD, [Context3DBlendFactor.ONE, Context3DBlendFactor.ONE]);
			RenderJob.premultipliedBlendFactors.set(BLEND_MULTIPLY, [Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA]);
			RenderJob.premultipliedBlendFactors.set(BLEND_SCREEN, [Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR]);

			RenderJob.noPremultipliedBlendFactors = new StringMap();
			RenderJob.noPremultipliedBlendFactors.set(BLEND_NORMAL, [Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA]);
			RenderJob.noPremultipliedBlendFactors.set(BLEND_ADD, [Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.DESTINATION_ALPHA]);
			RenderJob.noPremultipliedBlendFactors.set(BLEND_MULTIPLY, [Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA]);
			RenderJob.noPremultipliedBlendFactors.set(BLEND_SCREEN, [Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE]);
		}
	}
}
#end