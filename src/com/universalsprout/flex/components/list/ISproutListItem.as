package com.universalsprout.flex.components.list
{
	import mx.core.IDataRenderer;
	
	public interface ISproutListItem extends IDataRenderer
	{
		function get used():Boolean;
		function set used(value:Boolean):void;
		
		function get highlight():Boolean;
		function set highlight(value:Boolean):void;
		
		function get heightTo():Number;
		function tweenTo(xMove:Number, yMove:Number):void
	}
}