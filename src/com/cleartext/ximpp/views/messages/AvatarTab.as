package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.assets.Constants;
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.views.common.Avatar;
	
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	
	import mx.controls.Button;
	import mx.core.Container;
	import mx.core.UITextField;
	import mx.effects.Fade;
	import mx.events.CloseEvent;

	public class AvatarTab extends Avatar
	{
		private static const SELECTED_ALPHA:Number = 1.0;
		private static const OVER_ALPHA:Number = 1.0;
		private static const OUT_ALPHA:Number = 0.7;

		private var closeButton:Button;
		private var dropShaddow:DropShadowFilter = new DropShadowFilter(2);
		private var unreadMessageCount:UITextField;
		
		private var over:Boolean = false;
		
		private var _selected:Boolean = false;
		public function get selected():Boolean
		{
			return _selected;
		}
		public function set selected(value:Boolean):void
		{
			if(_selected != value)
			{
				_selected = value;
				var fade:Fade = new Fade(this);
				fade.alphaFrom = alpha;
				fade.alphaTo = (selected) ? SELECTED_ALPHA : ((over) ? OVER_ALPHA : OUT_ALPHA);
				fade.duration = 350;
				fade.play();

				invalidateProperties();
			}
		}
		
		public function AvatarTab()
		{
			super();
			
			addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
			addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
		}
		
		public function get chat():Chat
		{
			return data as Chat;
		}
		
		override protected function buddyChangedHandler(event:BuddyEvent):void
		{
			super.buddyChangedHandler(event);
			invalidateProperties();
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
			
			if(!unreadMessageCount)
			{
				unreadMessageCount = new UITextField();
				unreadMessageCount.styleName = "whiteBold";
				unreadMessageCount.height = 16;
				addChild(unreadMessageCount);
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			var chatBuddy:Buddy = buddy as Buddy;

			if(chatBuddy && unreadMessageCount)
			{
				if(chatBuddy.unreadMessageCount > 0)
				{
					if(selected)
					{
						chatBuddy.unreadMessageCount = 0;
						return;
					}

					unreadMessageCount.visible = true;
					unreadMessageCount.text = chatBuddy.unreadMessageCount.toString();
					unreadMessageCount.width = unreadMessageCount.textWidth + 4;
					invalidateDisplayList();
				}
				else if(unreadMessageCount.visible)
				{
					unreadMessageCount.visible = false;
					invalidateDisplayList();
				}
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
			
			over = true;
			closeButton.visible = true;
			filters = [dropShaddow];
			alpha = OVER_ALPHA;
			invalidateDisplayList();
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			over = false;
			closeButton.visible = false;
			filters = [];
			alpha = (selected) ? SELECTED_ALPHA : OUT_ALPHA;
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			unreadMessageCount.move(unscaledWidth - unreadMessageCount.width, -5);
			
			var g:Graphics = graphics;

			if(closeButton.visible)
			{
				g.beginFill(0xffffff);
				g.drawRect(48, 14, 12, 24);
				g.beginFill(0xffffff);
				g.drawCircle(60, 26, 12);
			}
			
			if(unreadMessageCount.visible)
			{
				g.beginFill(0xff0000);
				g.drawRoundRect(unscaledWidth - unreadMessageCount.width-2, -6, unreadMessageCount.width + 6, unreadMessageCount.height, unreadMessageCount.height);
			}
		}
	}
}