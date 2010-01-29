package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.models.ApplicationModel;
	import com.cleartext.ximpp.models.XimppUtils;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.views.common.Avatar;
	import com.universalsprout.flex.components.list.SproutListItemBase;
	
	import mx.core.IUITextField;
	import mx.core.UITextField;
	import mx.effects.Tween;

	public class MessageRenderer extends SproutListItemBase
	{
		[Autowire]
		[Bindable]
		public var appModel:ApplicationModel;
		
		//---------------------------------------
		// Constants
		//---------------------------------------
		
		private static const UITEXTFIELD_WIDTH_PADDING:Number = 5;
		private static const UITEXTFIELD_HEIGHT_PADDING:Number = 4;

		private static const TOP_BAR_HEIGHT:Number = 16;
		private static const PADDING:Number = 3;
		
		private static const NO_HIGHLIGHT:uint = 0xffffff;
		private static const HIGHLIGHT:uint = 0xb6b6dd;

		private static const AVATAR_SIZE:Number = 32;

		//---------------------------------------
		// Constructor
		//---------------------------------------
		
		public function MessageRenderer()
		{
			super();
			alpha = 0;
			// hack to force the textField to render slightly
			// smaller than the width of this container
			setStyle("paddingRight", 3*PADDING + AVATAR_SIZE);
		}
		
		//---------------------------------------
		// Message Data
		//---------------------------------------
		
		private function get message():Message
		{
			return data as Message;
		}
		
		override public function set data(value:Object):void
		{
			super.data = value;

			if(appModel && message)
				avatar.data = appModel.getBuddyByJid(message.sender);
		}
		
		//---------------------------------------
		// Alpha Tween
		//---------------------------------------
		
		private var alphaTween:Tween;
		
		//---------------------------------------
		// Display Children
		//---------------------------------------
		
		private var avatar:Avatar;
		private var fromLabel:UITextField;
		private var timeLabel:UITextField;
		private function get messageLabel():IUITextField
		{
			return textField;
		}

		//---------------------------------------
		// Create Children
		//---------------------------------------
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!avatar)
			{
				avatar = new Avatar();
				addChild(avatar);
			}
			
			if(!fromLabel)
			{
				fromLabel = new UITextField();
				addChild(fromLabel);
			}
			
			if(!timeLabel)
			{
				timeLabel = new UITextField();
				addChild(timeLabel);
			}
			
			data = data;
		}
		
		//---------------------------------------
		// Commit Properties
		//---------------------------------------
		
		override protected function commitProperties():void
		{
			if(!message)
				return;
			
			// set values
			messageLabel.htmlText = message.body;
			fromLabel.text = message.sender;
			timeLabel.text = message.timestamp.toTimeString();
			
			// refresh styles
			fromLabel.styleName = "lgreyNormal";
			timeLabel.styleName = "lgreyNormal";
			messageLabel.styleName = "dgreyNormal";
			
			// check layout of super.textField
			super.commitProperties();
			
			// if this is the first time we run then create a tween to fade in
			if(!alphaTween)
				alphaTween = new Tween(this, 0, 1, TWEEN_DURATION, -1, updateAlpha, updateAlpha);
			
			// set height
			height = textFieldHeight + TOP_BAR_HEIGHT + 3*PADDING;
			//trace("calculating " + height + " : " + messageLabel.numLines);

		}

		//---------------------------------------
		// Update Display List
		//---------------------------------------
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			//trace(unscaledWidth + " : " + unscaledHeight); 

			commitProperties();

			// draw background	
			graphics.clear();
			graphics.beginFill((highlight) ? HIGHLIGHT : NO_HIGHLIGHT, 0.18);
			graphics.drawRect(0, 0, unscaledWidth-1, unscaledHeight);
			
			// draw line at base
			graphics.beginFill(0xdddddd);
			graphics.drawRect(0, unscaledHeight-1, unscaledWidth-1, 1);
			
			// layout avatar
			avatar.setActualSize(AVATAR_SIZE, AVATAR_SIZE);
			avatar.move(PADDING, PADDING);
			
			// layout from label
			fromLabel.setActualSize(unscaledWidth - timeLabel.width - 3*PADDING-AVATAR_SIZE, fromLabel.height)
			fromLabel.move(AVATAR_SIZE + 2*PADDING, PADDING);
			
			// layout time label
			timeLabel.move(unscaledWidth - PADDING - timeLabel.width, PADDING);
			
			// layout message label
			messageLabel.move(AVATAR_SIZE + 2*PADDING, 2*PADDING + TOP_BAR_HEIGHT);
		}
	}
}