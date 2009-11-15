package com.cleartext.ximpp.views.timeline
{
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.universalsprout.flex.components.list.SproutListItemBase;
	
	import mx.core.IUITextField;
	import mx.core.UITextField;
	import mx.effects.Tween;

	public class MessageRenderer extends SproutListItemBase
	{
		private static const TOP_BAR_HEIGHT:Number = 16;
		private static const UITEXTFIELD_WIDTH_PADDING:Number = 5;
		private static const UITEXTFIELD_HEIGHT_PADDING:Number = 4;
		
		private var NO_HIGHLIGHT:uint = 0xffffff;
		private var HIGHLIGHT:uint = 0xb6b6dd;

		public function MessageRenderer()
		{
			super();
			setStyle("paddingRight", 8);
			alpha = 0;
		}
		
		private var alphaTween:Tween;
		
		private var fromLabel:UITextField;
		private var timeLabel:UITextField;
		private function get messageLabel():IUITextField
		{
			return textField;
		}
		
		private function get message():Message
		{
			return data as Message;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			fromLabel = new UITextField();
			addChild(fromLabel);
			
			timeLabel = new UITextField();
			addChild(timeLabel);
		}
		
		override protected function commitProperties():void
		{
			if(!message)
				return;
				
			fromLabel.styleName = "blackBold";
			timeLabel.styleName = "lgreyBold";
			messageLabel.styleName = "dgreyNormal";
			
			messageLabel.htmlText = message.htmlBody;

			super.commitProperties();
			
			if(!alphaTween)
				alphaTween = new Tween(this, 0, 1, TWEEN_DURATION, -1, updateAlpha, updateAlpha);
			
			fromLabel.text = message.publisher;
			timeLabel.text = message.timeStamp.toDateString();
			
			var paddingTop:Number = 4;
			var paddingBottom:Number = 2;

			height = textFieldHeight + TOP_BAR_HEIGHT + paddingTop + 2*paddingBottom;
			//trace("calculating " + height + " : " + messageLabel.numLines);
		}

		/**
		 *  @private
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			//trace(unscaledWidth + " : " + unscaledHeight); 

			commitProperties();

			var paddingLeft:Number = 2;
			var paddingTop:Number = 4;
			var paddingRight:Number = 2;
			var paddingBottom:Number = 2;

			messageLabel.height = unscaledHeight - paddingTop - 2*paddingBottom - TOP_BAR_HEIGHT;
	
			graphics.clear();
			graphics.beginFill((highlight) ? HIGHLIGHT : NO_HIGHLIGHT, 0.18);
			graphics.drawRect(0, 0, unscaledWidth-1, unscaledHeight);
			
			graphics.beginFill(0xdddddd);
			graphics.drawRect(0, unscaledHeight-1, unscaledWidth-1, 1);
			
			messageLabel.x = paddingLeft;
			messageLabel.y = paddingTop + paddingBottom + TOP_BAR_HEIGHT;

			fromLabel.move(paddingLeft, paddingTop);
			fromLabel.setActualSize(unscaledWidth-timeLabel.width-paddingLeft-2*paddingRight, fromLabel.height)
			
			timeLabel.move(unscaledWidth-paddingRight-timeLabel.width, paddingTop);
		}
	}
}