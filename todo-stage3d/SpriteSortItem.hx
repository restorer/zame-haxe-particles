package com.asliceofcrazypie.flash;

#if flash11
import flash.display3D.textures.Texture;
import flash.Vector;
import flash.Vector;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;

/**
 * ...
 * @author Paul M Pepper
 */
class SpriteSortItem
{

	public var sprite(default, null):Sprite;
	public var depths(default, null):Vector<Int>;
	
	private var renderJobs:Array<RenderJob>;
	
	public function new( sprite:Sprite )
	{
		this.sprite = sprite;
		this.depths = new Vector<Int>();
		renderJobs = [];
	}
	
	public inline function addJob( renderJob:RenderJob ):Void
	{
		renderJobs.push( renderJob );
	}
	
	public inline function clearJobs():Int
	{
		for ( renderJob in renderJobs )
		{
			RenderJob.returnJob( renderJob );
		}
		var jobs:Int = renderJobs.length;
		untyped renderJobs.length = 0;
		
		return jobs;
	}
	
	private inline function update():Void
	{
		this.depths.length = 0;
		
		var parent:DisplayObjectContainer = this.sprite.parent;
		var current:DisplayObjectContainer = sprite;
		
		while ( parent != null )
		{
			depths.push( parent.getChildIndex( current ) );
			
			//work up the tree
			parent = parent.parent;
			current = current.parent;
		}
	}
	
	public inline function renderBuffers( context:ContextWrapper ):Int
	{
		//work though buffers list rendering each in order
		for ( renderJob in renderJobs )
		{
			renderJob.render( context );
		}
		
		return renderJobs.length;
	}
	
	public function toString():String
	{
		return '[SpriteSortItem depths="'+depths+'" item="'+sprite+'"]';
	}
	
	/**
	 * In-place sort of SpriteSortItems
	 * 
	 * @param	items
	 */
	public static inline function sortItems( items:Vector<SpriteSortItem> ):Void
	{
		for ( item in items )
		{
			item.update();
		}
		
		items.sort( sortFunction );
	}
	
	static private function sortFunction( a:SpriteSortItem, b:SpriteSortItem ):Int
	{
		if ( a.sprite == b.sprite )
		{
			return 0;
		}
		
		var currentDepthA:Int;
		var currentDepthB:Int;
		var currentDepthIndA:Int = a.depths.length - 1;
		var currentDepthIndB:Int = b.depths.length - 1;
		
		
		while ( currentDepthIndA >= 0 && currentDepthIndB >= 0 )
		{
			currentDepthA = a.depths[currentDepthIndA--];
			currentDepthB = b.depths[currentDepthIndB--];
			
			if ( currentDepthA > currentDepthB )
			{
				return 1;
			}
			else if ( currentDepthA < currentDepthB )
			{
				return -1;
			}
		}
		
		return a.depths.length - b.depths.length;//this catches situations where one item is the child of another
	}
}
#end