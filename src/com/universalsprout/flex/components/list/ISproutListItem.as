package com.universalsprout.flex.components.list
{
	import mx.core.IDataRenderer;
	
	public interface ISproutListItem extends IDataRenderer
	{
		function get highlight():Boolean;
		function set highlight(value:Boolean):void;
		
		function get heightTo():Number;
		function tweenTo(xMove:Number, yMove:Number):void
	}
}