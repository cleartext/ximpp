package com.cleartext.ximpp.views.messages
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;

	public class CustomScrollbar extends UIComponent
	{
		private var _value:Number=0;
		[Bindable(event="scrollChanged")]
		public function get value():Number
		{
			return _value;
		}
		public function set value(v:Number):void
		{
			if(v!=value)
			{
				_value = v;
				dispatchEvent(new Event("scrollChanged"));
				invalidateDisplayList();
			}
		}

		private var ratioVisible:Number = 0.38;
		private var prevX:Number;
		private var thumb:Sprite;
		
		public function CustomScrollbar()
		{
			super();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!thumb)
			{
				thumb = new Sprite();
				thumb.addEventListener(MouseEvent.MOUSE_DOWN, thumb_mouseDownHandler);
				addChild(thumb);
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var g:Graphics = thumb.graphics;
			
			g.clear();
			g.beginFill(0xffffff);
			g.drawRoundRect(unscaledWidth * (value-ratioVisible), 0, unscaledWidth * ratioVisible, unscaledHeight, unscaledHeight, unscaledHeight);
			
			g = graphics;
			g.clear();
			g.beginFill(0xffffff, 0.25);
			g.drawRoundRect(0, 0, unscaledWidth, unscaledHeight, unscaledHeight, unscaledHeight);
		}
		
		private function thumb_mouseDownHandler(event:MouseEvent):void
		{
			prevX = stage.mouseX;
			systemManager.addEventListener(MouseEvent.MOUSE_MOVE, system_mouseMoveHandler);
			systemManager.addEventListener(MouseEvent.MOUSE_UP, system_mouseUpHandler);
		}
		
		private function system_mouseMoveHandler(event:MouseEvent):void
		{
			var dx:Number = stage.mouseX - prevX;
			prevX = stage.mouseX;
			
			var spaceToMove:Number = width * (1-ratioVisible);
			value += dx/spaceToMove;
		}
		
		private function system_mouseUpHandler(event:MouseEvent):void
		{
			systemManager.removeEventListener(MouseEvent.MOUSE_MOVE, system_mouseMoveHandler);
			systemManager.removeEventListener(MouseEvent.MOUSE_UP, system_mouseUpHandler);
		}
		
		public function setRange(viewSize:Number, totalSize:Number):void
		{
			var newRatio:Number = viewSize/totalSize;
			if(newRatio != ratioVisible)
			{
				ratioVisible = newRatio;
				invalidateDisplayList();
			}
		}
		
		
	}
}