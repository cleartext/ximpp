package com.cleartext.esm.views.messages
{
	import com.cleartext.esm.assets.Constants;
	import com.cleartext.esm.events.AvatarEvent;
	import com.cleartext.esm.events.HasAvatarEvent;
	import com.cleartext.esm.models.ContactModel;
	import com.cleartext.esm.models.types.AvatarTypes;
	import com.cleartext.esm.models.types.BuddyTypes;
	import com.cleartext.esm.models.valueObjects.Buddy;
	import com.cleartext.esm.models.valueObjects.BuddyGroup;
	import com.cleartext.esm.models.valueObjects.Chat;
	import com.cleartext.esm.models.valueObjects.ChatRoom;
	import com.cleartext.esm.models.valueObjects.Contact;
	import com.cleartext.esm.views.common.AvatarRenderer;
	import com.cleartext.esm.views.common.UnreadMessageBadge;
	import com.cleartext.esm.views.popup.ChangePasswordWindow;
	
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	
	import flashx.textLayout.formats.Category;
	
	import mx.controls.Button;
	import mx.controls.Text;
	import mx.core.Container;
	import mx.core.IInvalidating;
	import mx.core.UITextField;
	import mx.effects.Fade;
	import mx.events.CloseEvent;
	
	import spark.components.Group;
	import spark.effects.interpolation.IInterpolator;

	public class AvatarTab extends AvatarRenderer
	{
		public static const SELECTED_ALPHA:Number = 1.0;
		public static const OVER_ALPHA:Number = 1.0;
		public static const OUT_ALPHA:Number = 0.7;
		
		private var closeButton:Button;
		private var nickNameText:UITextField;
		private var dropShaddow:DropShadowFilter = new DropShadowFilter(2);
		private var unreadMessageBadge:UnreadMessageBadge;
		
		private var _showNickname:Boolean = false;
		public function get showNickname():Boolean 
		{
			return _showNickname;
		}
		public function set showNickname(value:Boolean):void
		{
			if(value != showNickname)
			{
				_showNickname = value;
				smallAvatar = value;
				invalidateProperties();
			}
		}
		
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
				
				if(selected && chat && chat.contact)
					chat.contact.unreadMessages = 0;

				invalidateProperties();
			}
		}
		
		public function AvatarTab()
		{
			super();
			
			addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
			addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
		}
		
		private var _chat:Chat;
		public function get chat():Chat
		{
			return _chat;
		}
		public function set chat(value:Chat):void
		{
			if(chat != value)
			{
				if(chat && chat.contact)
					chat.contact.removeEventListener(HasAvatarEvent.CHANGE_SAVE, buddyChangedHandler);
					
				_chat = value;

				if(chat && chat.contact)
					chat.contact.addEventListener(HasAvatarEvent.CHANGE_SAVE, buddyChangedHandler);
			}
		}
		
		override protected function avatarChangedHandler(event:AvatarEvent):void
		{
			super.avatarChangedHandler(event);
			invalidateProperties();
		}
		
		protected function buddyChangedHandler(event:HasAvatarEvent):void
		{
			invalidateProperties();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!nickNameText)
			{
				nickNameText = new UITextField();
				nickNameText.multiline = true;
				nickNameText.mouseEnabled = false;
				nickNameText.visible = showNickname;
				nickNameText.wordWrap = true;
				nickNameText.styleName = "blackBold";
				addChild(nickNameText);
			}
			
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
				closeButton.buttonMode = true;
				addChild(closeButton);
			}
			
			if(!unreadMessageBadge)
			{
				unreadMessageBadge = new UnreadMessageBadge();
				addChild(unreadMessageBadge);
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			var contact:Contact = (chat) ? chat.contact : null;

			if(contact)
			{
				if(contact == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					type = AvatarTypes.ALL_MICRO_BLOGGING_BUDDY;
				else if(contact is BuddyGroup)
					type = AvatarTypes.GROUP;
				else if(contact is ChatRoom)
					type = AvatarTypes.CHAT_ROOM;
				else 
					type = AvatarTypes.BUDDY;
				
				if(unreadMessageBadge)
				{
					if(unreadMessageBadge.count != contact.unreadMessages)
						callLater(invalidateProperties);
					unreadMessageBadge.count = contact.unreadMessages;
					unreadMessageBadge.x = width - unreadMessageBadge.width + 5;
					unreadMessageBadge.y = -unreadMessageBadge.height/2;
				}
				
				if(showNickname)
				{
					nickNameText.text = contact.nickname;
					nickNameText.truncateToFit(null);
				}
			}
			
			nickNameText.visible = showNickname;
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
			dirty = true;
			invalidateDisplayList();
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			over = false;
			closeButton.visible = false;
			filters = [];
			alpha = (selected) ? SELECTED_ALPHA : OUT_ALPHA;
			dirty = true;
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var g:Graphics = graphics;
			
			if(showNickname)
			{
				var xVal:Number = (showAvatar) ? unscaledHeight/2 + 3 : 3 
				nickNameText.move(xVal, 2);
				nickNameText.setActualSize(unscaledWidth-xVal-3, unscaledHeight-4);
			}

			if(closeButton.visible)
			{
				closeButton.move(unscaledWidth+4,19);
				g.beginFill(0xffffff);
				g.drawRect(unscaledWidth, 14, 12, 24);
				g.beginFill(0xffffff);
				g.drawCircle(unscaledWidth+12, 26, 12);
			}
		}
	}
}