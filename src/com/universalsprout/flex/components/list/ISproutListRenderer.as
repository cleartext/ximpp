package com.universalsprout.flex.components.list
{
	import mx.core.IDataRenderer;
	import mx.core.IUIComponent;
	
	public interface ISproutListRenderer extends IDataRenderer, IUIComponent, IDisposable
	{
		function get heightTo():Number;
		function set heightTo(value:Number):void
		
		function get yTo():Number
		function set yTo(value:Number):void
		
		function setIncludeInLayout(value:Boolean, noEvent:Boolean=false):void
		
		function setWidth(widthVal:Number):Number;
	}
}