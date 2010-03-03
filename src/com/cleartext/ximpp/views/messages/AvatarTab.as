package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.models.Constants;
	import com.cleartext.ximpp.views.common.Avatar;
	
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	
	import mx.controls.Button;
	import mx.core.Container;
	import mx.events.CloseEvent;

	public class AvatarTab extends Avatar
	{
		private var closeButton:Button;
		private var dropShaddow:DropShadowFilter = new DropShadowFilter(2);
		
		public function AvatarTab()
		{
			super();
			
			addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
			addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!closeButton)
			{
				closeButton = new Button();
				closeButton.addEventListener(MouseEvent.CLICK, closeButtonHandler);
				closeButton.visible = false;
				closeButton.setStyle("skin", null);
				closeButton.setStyle("upIcon", Constants.CloseUp);
				closeButton.setStyle("overIcon", Constants.CloseOver);
				closeButton.setStyle("downIcon", Constants.CloseUp);
				closeButton.width = 14;
				closeButton.height = 14;
				closeButton.x = 52;
				closeButton.y = 19;
				closeButton.buttonMode = true;
				addChild(closeButton);
			}
		}
		
		private function closeButtonHandler(event:MouseEvent):void
		{
			event.stopPropagation();
			dispatchEvent(new CloseEvent(CloseEvent.CLOSE));
		}
		
		private function rollOverHandler(event:MouseEvent):void
		{
			var p:Container = parent as Container;
			
			if(p)
				p.setChildIndex(this, p.numChildren-1);
				
			closeButton.visible = true;
			filters = [dropShaddow];
			invalidateDisplayList();
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			closeButton.visible = false;
			filters = [];
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if(closeButton.visible)
			{
				var g:Graphics = graphics;
				
				g.beginFill(0xffffff);
				g.drawRect(48, 14, 12, 24);
				g.beginFill(0xffffff);
				g.drawCircle(60, 26, 12);
			}
		}
		
	}
}