package com.cleartext.ximpp.views.buddies
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.views.common.StatusIcon;
	import com.universalsprout.flex.components.list.SproutListItemBase;
	
	import flash.events.Event;
	
	import mx.core.IUITextField;
	import mx.core.UITextField;
	import mx.effects.Tween;

	public class BuddyRenderer extends SproutListItemBase
	{
		private static const SMALL_HEIGHT:Number = 40;
		private static const BIG_HEIGHT:Number = 54;
		
		private var NO_HIGHLIGHT:uint = 0xffffff;
		private var HIGHLIGHT:uint = 0xb6b6dd;

		public function BuddyRenderer()
		{
			super();
			height = SMALL_HEIGHT;
			wordWrap = false;
			setStyle("paddingRight", 8);
			truncateToFit = true;
		}
				
		private var sizeTween:Tween;
		
		private function get buddy():Buddy
		{
			return data as Buddy;
		}
		
		private var statusIcon:StatusIcon;
		private var nameLabel:UITextField;
		private var statusLabel:UITextField;
		private function get customStatusLabel():IUITextField
		{
			return textField;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!statusIcon)
			{
				statusIcon = new StatusIcon();
				addChild(statusIcon);
			}

			if(!nameLabel)
			{
				nameLabel = new UITextField();
				addChild(nameLabel);
			}

			if(!statusLabel)
			{
				statusLabel = new UITextField();
				addChild(statusLabel);
			}

			customStatusLabel.visible = false;
			customStatusLabel.wordWrap = true;
		}
		
		override protected function dataChangedHandler(event:Event):void
		{
			invalidateProperties();
		}
		
		override protected function commitProperties():void
		{
			if(!buddy)
				return;

			customStatusLabel.text = buddy.customStatus;
			
			nameLabel.styleName = "blackBold";
			statusLabel.styleName = "lgreyNormal";
			customStatusLabel.styleName = "dgreyNormal";

			super.commitProperties();
			
			nameLabel.text = buddy.nickName;
			statusLabel.text = buddy.status;
			statusIcon.status = buddy.status;
			
			customStatusLabel.truncateToFit();

			var h:Number = BIG_HEIGHT;

			if(buddy.customStatus == "")
			{
				customStatusLabel.visible = false;
				h = SMALL_HEIGHT;
			}

			if(h != heightTo)
			{
				_heightTo = h;
				if(sizeTween)
					sizeTween.stop();
				
				sizeTween = new Tween(this, height, h, TWEEN_DURATION, -1, updateHeight,
					function():void
					{
						customStatusLabel.visible = true;
						sizeTween = null;
						updateHeight(heightTo);
						_heightTo = NaN;
						commitProperties();
					});
			}
		}		
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			textField.wordWrap = wordWrap;
			
			commitProperties();
			
			graphics.clear();
			graphics.beginFill((highlight) ? HIGHLIGHT : NO_HIGHLIGHT, 0.18);
			graphics.drawRect(0, 0, unscaledWidth-1, unscaledHeight);
			
			nameLabel.setActualSize(unscaledWidth-8, nameLabel.height);
			nameLabel.move(4, 4);

			statusIcon.move(4, 21);

			statusLabel.setActualSize(unscaledWidth-8-StatusIcon.SIZE, statusLabel.height); 
			statusLabel.move(18, 20);

			customStatusLabel.setActualSize(unscaledWidth-8, customStatusLabel.height);
			customStatusLabel.move(4, 37);
		}
	}
}