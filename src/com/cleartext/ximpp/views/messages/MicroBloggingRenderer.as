package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.events.MicroBloggingMessageEvent;
	import com.cleartext.ximpp.models.Constants;
	import com.cleartext.ximpp.models.types.MessageStatusTypes;
	import com.cleartext.ximpp.models.types.MicroBloggingMessageTypes;
	import com.cleartext.ximpp.models.valueObjects.Status;
	import com.cleartext.ximpp.views.common.StatusIcon;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	
	import mx.controls.Button;
	
	import org.swizframework.Swiz;
	
	public class MicroBloggingRenderer extends MessageRendererBase
	{
		protected var buttonWidth:Number = 16;
		protected var buttons:Array = new Array();
		
		private var _messageType:String = MicroBloggingMessageTypes.UNKNOWN_TYPE;
		public function get messageType():String
		{
			return _messageType;
		}
		public function set messageType(value:String):void
		{
			if(value != _messageType)
			{
				_messageType = value;
				
				// remove all existing buttons
				for each(var button:DisplayObject in buttons)
					removeChild(button);
				buttons = new Array();
				
				switch(_messageType)
				{
					case MicroBloggingMessageTypes.TWEET_SENT :
						
						var statusIcon:StatusIcon = new StatusIcon();
						statusIcon.width = 16;
						statusIcon.height = 16;
						statusIcon.alpha = 0.75;
						statusIcon.x = padding;
						statusIcon.y = padding;
						buttons.push(statusIcon);
						addChild(statusIcon);
						
						var deleteButton:Button = new Button();
						deleteButton.data = MicroBloggingMessageEvent.TWITTER_DELETE;
						deleteButton.addEventListener(MouseEvent.CLICK, button_clickHandler);
						deleteButton.toolTip = "delete";
						deleteButton.setStyle("skin", null);
						deleteButton.setStyle("upIcon", Constants.DeleteUp);
						deleteButton.setStyle("overIcon", Constants.DeleteOver);
						deleteButton.setStyle("downIcon", Constants.DeleteUp);
						deleteButton.width = 16;
						deleteButton.height = 16;
						deleteButton.y = 1.5*padding + 16;
						deleteButton.x = padding;
						deleteButton.buttonMode = true;
						buttons.push(deleteButton);
						addChild(deleteButton);

						break;

					case MicroBloggingMessageTypes.TWEET_RECEIVED :
						var reply:Button = new Button();
						reply.data = MicroBloggingMessageEvent.TWITTER_REPLY;
						reply.addEventListener(MouseEvent.CLICK, button_clickHandler);
						reply.toolTip = "reply";
						reply.setStyle("skin", null);
						reply.setStyle("upIcon", Constants.ReplyUp);
						reply.setStyle("overIcon", Constants.ReplyOver);
						reply.setStyle("downIcon", Constants.ReplyUp);
						reply.width = 16;
						reply.height = 16;
						reply.y = padding;
						reply.x = padding;
						reply.buttonMode = true;
						buttons.push(reply);
						addChild(reply);

						var retweet:Button = new Button();
						retweet.data = MicroBloggingMessageEvent.TWITTER_RETWEET;
						retweet.addEventListener(MouseEvent.CLICK, button_clickHandler);
						retweet.toolTip = "retweet";
						retweet.setStyle("skin", null);
						retweet.setStyle("upIcon", Constants.RetweetUp);
						retweet.setStyle("overIcon", Constants.RetweetOver);
						retweet.setStyle("downIcon", Constants.ReplyUp);
						retweet.width = 16;
						retweet.height = 16;
						retweet.y = 1.5*padding + 16;
						retweet.x = padding;
						retweet.buttonMode = true;
						buttons.push(retweet);
						addChild(retweet);

						var directMessage:Button = new Button();
						directMessage.data = MicroBloggingMessageEvent.TWITTER_DIRECT_MESSAGE;
						directMessage.addEventListener(MouseEvent.CLICK, button_clickHandler);
						directMessage.toolTip = "direct message";
						directMessage.setStyle("skin", null);
						directMessage.setStyle("upIcon", Constants.DirectMessageUp);
						directMessage.setStyle("overIcon", Constants.DirectMessageOver);
						directMessage.setStyle("downIcon", Constants.DirectMessageUp);
						directMessage.width = 16;
						directMessage.height = 16;
						directMessage.y = 2*padding + 32;
						directMessage.x = padding;
						directMessage.buttonMode = true;
						buttons.push(directMessage);
						addChild(directMessage);

						break;

					default :
						break;
				}
			}
		}
		
		override public function set data(value:Object):void
		{
			if(message)
				message.removeEventListener(MicroBloggingMessageEvent.MESSAGE_STATUS_CHANGED, messageStatusChangeHandler);
			
			super.data = value;
			
			if(message)
				message.addEventListener(MicroBloggingMessageEvent.MESSAGE_STATUS_CHANGED, messageStatusChangeHandler);
		}	
			
		public function MicroBloggingRenderer()
		{
			super();
			
			avatarSize = 42;
			topRowHeight = 42;
			padding = 8;
		}

		private function messageStatusChangeHandler(event:MicroBloggingMessageEvent):void
		{
			if(buttons.length > 0)
			{
				var statusIcon:StatusIcon = buttons[0] as StatusIcon;
				if(statusIcon)
				{
					switch(message.status)
					{
						case MessageStatusTypes.ERROR :
							statusIcon.status.value = Status.ERROR;
							break;
						case MessageStatusTypes.PENDING :
							statusIcon.status.value = Status.CONNECTING;
							break;
						case MessageStatusTypes.SUCCESS :
							statusIcon.status.value = Status.AVAILABLE;
							break;
						default :
							statusIcon.status.value = Status.UNKNOWN;
							break;
					}
				}
			}

		}

		private function button_clickHandler(event:MouseEvent):void
		{
			var type:String = event.target.data;
			Swiz.dispatchEvent(new MicroBloggingMessageEvent(type, message));
		}

		override protected function get bodyTextWidth():Number
		{
			return width - 5*padding - avatarSize - buttonWidth;
		}
		
		override protected function calculateHeight():Number
		{
			heightTo = super.calculateHeight() + topRowHeight + padding;
			return heightTo;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
	
			if(message.sender == "twitter.cleartext.com")
				messageType = MicroBloggingMessageTypes.TWEET_RECEIVED;
			
			if(fromThisUser)
				messageType = MicroBloggingMessageTypes.TWEET_SENT;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			avatar.x = 2*padding + buttonWidth;
			avatar.y = padding;

			dateTextField.x = avatarSize + 3*padding + buttonWidth;
			dateTextField.y = padding;

			nameTextField.x = avatarSize + 3*padding + buttonWidth;
			nameTextField.y = padding*2 + 8;

			bodyTextField.x = avatarSize + 3*padding + buttonWidth;
			bodyTextField.y = topRowHeight;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var g:Graphics = graphics;
			g.clear();

			if(!fromThisUser)
			{
				var matrix:Matrix = new Matrix();
				matrix.createGradientBox(width, heightTo, Math.PI/2);
				
				g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xdedede], [0.5, 0.5], [95, 255], matrix);
				g.drawRect(0, 0, width, heightTo);
			}

			g.lineStyle(1, 0xdedede, 0.75);
			g.moveTo(0,heightTo);
			g.lineTo(width, heightTo);
		}
		
	}
}