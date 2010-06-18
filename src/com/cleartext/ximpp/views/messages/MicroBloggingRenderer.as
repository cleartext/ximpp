package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.assets.Constants;
	import com.cleartext.ximpp.events.HasAvatarEvent;
	import com.cleartext.ximpp.events.InputTextEvent;
	import com.cleartext.ximpp.models.types.MicroBloggingTypes;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.IBuddy;
	import com.cleartext.ximpp.models.valueObjects.MicroBloggingBuddy;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import mx.controls.Button;
	
	import org.swizframework.Swiz;
	
	public class MicroBloggingRenderer extends MessageRendererBase
	{		
		protected var buttonWidth:Number = 16;
		protected var buttons:Array = new Array();
		
		private var chatBuddy:IBuddy;
		private var mBlogSender:MicroBloggingBuddy;
		private var type:String = "";
			
		public function MicroBloggingRenderer()
		{
			super();
			
			avatarSize = 42;
			topRowHeight = 42;
			padding = 8;
		}

		public function createButtons(type:String):void
		{
			if(this.type == type)
				return;
			
			// remove all existing buttons
			for each(var button:DisplayObject in buttons)
				removeChild(button);
			buttons = new Array();
			
			switch(type)
			{
				case MicroBloggingTypes.RECEIVED :
					avatar.buttonMode = true;
					avatar.addEventListener(MouseEvent.CLICK, button_clickHandler, false, 0, true);
				
					var reply:Button = new Button();
					reply.data = "reply";
					reply.addEventListener(MouseEvent.CLICK, button_clickHandler, false, 0, true);
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
					retweet.data = "retweet";
					retweet.addEventListener(MouseEvent.CLICK, button_clickHandler, false, 0, true);
					retweet.toolTip = "retweet";
					retweet.setStyle("skin", null);
					retweet.setStyle("upIcon", Constants.RetweetUp);
					retweet.setStyle("overIcon", Constants.RetweetOver);
					retweet.setStyle("downIcon", Constants.RetweetUp);
					retweet.width = 16;
					retweet.height = 16;
					retweet.y = 1.5*padding + 16;
					retweet.x = padding;
					retweet.buttonMode = true;
					buttons.push(retweet);
					addChild(retweet);

					var directMessage:Button = new Button();
					directMessage.data = "direct";
					directMessage.addEventListener(MouseEvent.CLICK, button_clickHandler, false, 0, true);
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

		private function button_clickHandler(event:MouseEvent):void
		{
			if(event.target == avatar)
			{
				if(mBlogSender.profileUrl)
					navigateToURL(new URLRequest(mBlogSender.profileUrl));
			}
			else
			{
				switch(event.target.data)
				{
					case "reply" :
						Swiz.dispatchEvent(new InputTextEvent(InputTextEvent.INSERT_TEXT, "@" + message.mBlogSender.userName + " "));
						break;
					case "retweet" :
						Swiz.dispatchEvent(new InputTextEvent(InputTextEvent.INSERT_TEXT, "RT @" + message.mBlogSender.userName + " : " + bodyTextField.text));
						break;
					case "direct" :
						var buddy:IBuddy = appModel.getBuddyByJid(message.mBlogSender.jid);
						if(!buddy)
						{
							buddy = new Buddy(message.mBlogSender.jid);
							appModel.buddies.addBuddy(buddy);
						}
						chats.getChat(buddy, true);
						break;
				}
			}
			
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
		
		protected function buddyChangeHandler(event:HasAvatarEvent):void
		{
			invalidateProperties();
		}
		
		override protected function commitProperties():void
		{
			if(message)
			{
				if(!chatBuddy || chatBuddy.jid != message.sender)
				{
					if(chatBuddy)
						chatBuddy.removeEventListener(HasAvatarEvent.CHANGE_SAVE, buddyChangeHandler);

					chatBuddy =  appModel.getBuddyByJid(message.sender);

					if(chatBuddy)
						chatBuddy.addEventListener(HasAvatarEvent.CHANGE_SAVE, buddyChangeHandler, false, 0, true);
					
					fromThisUser = (chatBuddy == userAccount);
				}
				
				if(message.mBlogSender)
				{
					if(mBlogSender != message.mBlogSender)
					{
						if(mBlogSender)
							mBlogSender.removeEventListener(HasAvatarEvent.CHANGE_SAVE, buddyChangeHandler);
	
						mBlogSender = message.mBlogSender;
	
						if(mBlogSender)
						{
							mBlogSender.addEventListener(HasAvatarEvent.CHANGE_SAVE, buddyChangeHandler, false, 0, true);
							createButtons(MicroBloggingTypes.RECEIVED);
						}
						else
						{
							createButtons(null);
						}
	
						avatar.data = mBlogSender;
					}
					nameTextField.text = mBlogSender.nickname; 
				}
				else if(chatBuddy)
				{
					avatar.data = chatBuddy;
					nameTextField.text = chatBuddy.nickname;
					createButtons(null); 
				}
				
				nameTextField.width = nameTextField.textWidth + padding*4;
				nameTextField.styleName = (fromThisUser) ? "lGreyBold" : "blackBold";

				dateTextField.text = df.format(message.sortDate);
				dateTextField.width = dateTextField.textWidth + padding*2;
				dateTextField.styleName = (fromThisUser) ? "lGreySmall" : "blackSmall";
				
				if(message.displayMessage)
					bodyTextField.htmlText = message.displayMessage;
				else
					bodyTextField.text = message.plainMessage;

				bodyTextField.styleName = (fromThisUser) ? "lGreyNormal" : "blackNormal";
			}
					
			heightInvalid = true;
			calculateHeight();
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