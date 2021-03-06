package com.cleartext.esm.views.messages
{
	import com.cleartext.esm.assets.Constants;
	import com.cleartext.esm.events.AvatarEvent;
	import com.cleartext.esm.events.HasAvatarEvent;
	import com.cleartext.esm.events.InputTextEvent;
	import com.cleartext.esm.events.LinkEvent;
	import com.cleartext.esm.models.ApplicationModel;
	import com.cleartext.esm.models.AvatarModel;
	import com.cleartext.esm.models.XMPPModel;
	import com.cleartext.esm.models.types.AvatarTypes;
	import com.cleartext.esm.models.types.MicroBloggingTypes;
	import com.cleartext.esm.models.valueObjects.Avatar;
	import com.cleartext.esm.models.valueObjects.Buddy;
	import com.cleartext.esm.models.valueObjects.Contact;
	import com.seesmic.as3.xmpp.XMPPEvent;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.controls.Button;
	import mx.core.UITextField;
	
	import org.swizframework.Swiz;
	
	public class MicroBloggingRenderer extends MessageRendererBase
	{	
		protected function get xmpp():XMPPModel
		{
			return appModel.xmpp;
		}

		protected var buttonWidth:Number = 16;
		protected var buttons:Array = new Array();
	
		protected var searchTerms:UITextField;
		private var type:String = "";
		
		private var avatarContextMenu:ContextMenu;
		private var followItem:ContextMenuItem;
		private var unFollowItem:ContextMenuItem;
		
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
		
		private var _mblogAvatar:Avatar;
		public function get mblogAvatar():Avatar
		{
			return _mblogAvatar;
		}
		public function set mblogAvatar(value:Avatar):void
		{
			if(mblogAvatar != value)
			{
				if(mblogAvatar)
					mblogAvatar.removeEventListener(AvatarEvent.MBLOG_VALUES_CHANGE, mblogAvatarChangeHandler);

				_mblogAvatar = value;
				
				if(mblogAvatar)
				{
					mblogAvatar.addEventListener(AvatarEvent.MBLOG_VALUES_CHANGE, mblogAvatarChangeHandler);
					createButtons(MicroBloggingTypes.RECEIVED);
					if(mblogAvatar.profileUrl)
					{
						avatarRenderer.addEventListener(MouseEvent.CLICK, goToProfile);
						avatarRenderer.buttonMode = true;
					}
				}
				else
				{
					createButtons(null);
				}
				mblogAvatarChangeHandler(null);
			}
		}
		
		private function mblogAvatarChangeHandler(event:AvatarEvent):void
		{
			message.userAndDisplayName = mblogAvatar.userName + " " + mblogAvatar.displayName;
			invalidateProperties();
		}
		
		private function goToProfile(event:MouseEvent):void
		{
			if(mblogAvatar && mblogAvatar.profileUrl)
				Swiz.dispatchEvent(new LinkEvent(LinkEvent.LINK_CLICKED, mblogAvatar.profileUrl));
		}

		private function button_clickHandler(event:MouseEvent):void
		{
			switch(event.target.data)
			{
				case "reply" :
					Swiz.dispatchEvent(new InputTextEvent(InputTextEvent.INSERT_TEXT, "@" + mblogAvatar.userName + " "));
					break;
				case "retweet" :
					Swiz.dispatchEvent(new InputTextEvent(InputTextEvent.INSERT_TEXT, "RT @" + mblogAvatar.userName + " : " + bodyTextField.text));
					break;
				case "direct" :
					var buddy:Contact = appModel.getContactByJid(mblogAvatar.jid);
					if(!buddy)
					{
						buddy = new Buddy(mblogAvatar.jid);
						appModel.buddies.addBuddy(buddy);
					}
					chats.getChat(buddy, true);
					break;
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
		
		private function showContextMenu(event:MouseEvent):void
		{
			if(mblogAvatar && (message.sender == xmpp.cleartextComponentJid || message.sender == xmpp.twitterGatewayJid))
			{
				if(!followItem)
				{
					followItem = new ContextMenuItem("follow @" + mblogAvatar.userName);
					followItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, followHandler);
					avatarContextMenu.addItem(followItem);
				}
				if(!unFollowItem)
				{
					unFollowItem = new ContextMenuItem("unfollow @" + mblogAvatar.userName);
					unFollowItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, followHandler);
					avatarContextMenu.addItem(unFollowItem);
				}
			}
			else
			{
				if(followItem)
				{
					avatarContextMenu.removeItem(followItem);
					followItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT, followHandler);
					followItem = null;
				}
				if(unFollowItem)
				{
					avatarContextMenu.removeItem(unFollowItem);
					unFollowItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT, followHandler);
					unFollowItem = null;
				}
			}
		}
		
		private function followHandler(event:ContextMenuEvent):void
		{
			if(!xmpp.connected)
				return;
			xmpp.sendMessage(message.sender, (event.target == unFollowItem ? "u " : "f ") + mblogAvatar.userName);
		}
		
		override protected function commitProperties():void
		{
			if(message)
			{
				if(message.mBlogSenderJid)
				{
					mblogAvatar = avatarModel.getAvatar(message.mBlogSenderJid);
					nameTextField.text = mblogAvatar.displayName + " (@" + mblogAvatar.userName + ")"; 
					if(avatarRenderer)
						avatarRenderer.avatar = mblogAvatar;
				}
				else
				{
					fromThisUser = settings && message.sender == settings.userAccount.jid;
					avatar = fromThisUser ? avatarModel.userAccountAvatar : avatarModel.getAvatar(message.sender);
					nameTextField.text = avatar.displayName;
					if(avatarRenderer)
						avatarRenderer.avatar = avatar;
				}

				searchTerms.text = (message.searchTerms && message.searchTerms.length > 0) ? message.searchTerms.join(",") : '';
				searchTerms.width = searchTerms.textWidth + padding*4;
				searchTerms.styleName = "blackBold";
				searchTerms.x = width - searchTerms.width - padding;	
				
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
			
			if(!searchTerms)
			{
				searchTerms = new UITextField();
				searchTerms.autoSize = TextFieldAutoSize.NONE;
				searchTerms.ignorePadding = true;
				searchTerms.multiline = false;
				searchTerms.selectable = true;
				searchTerms.type = TextFieldType.DYNAMIC;
				searchTerms.y = padding;
				searchTerms.wordWrap = false;
				addChildAt(searchTerms,0);
			}
			
			avatarRenderer.x = 2*padding + buttonWidth;
			avatarRenderer.y = padding;
			
			dateTextField.x = avatarSize + 3*padding + buttonWidth;
			dateTextField.y = padding;

			nameTextField.x = avatarSize + 3*padding + buttonWidth;
			nameTextField.y = padding*2 + 8;

			bodyTextField.x = avatarSize + 3*padding + buttonWidth;
			bodyTextField.y = topRowHeight;
			
			if(!avatarContextMenu)
			{
				avatarContextMenu = new ContextMenu();
				avatarRenderer.addEventListener(MouseEvent.CONTEXT_MENU, showContextMenu);
				avatarRenderer.contextMenu = avatarContextMenu;
			}
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
				g.endFill();
			}

			g.lineStyle(1, 0xdedede, 0.75);
			g.moveTo(0,heightTo);
			g.lineTo(width, heightTo);
			g.lineStyle();
			
			if(searchTerms.text != "")
			{
				g.beginBitmapFill(new Constants.SearchUp().bitmapData, new Matrix(1,0,0,1,unscaledWidth-24-padding, 2), false);
				g.drawRect(unscaledWidth-24-padding,2, 24,24);
			}
		}
		
	}
}