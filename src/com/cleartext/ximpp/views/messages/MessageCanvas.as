package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.assets.Constants;
	import com.cleartext.ximpp.events.ChatEvent;
	import com.cleartext.ximpp.events.SearchBoxEvent;
	import com.cleartext.ximpp.models.ApplicationModel;
	import com.cleartext.ximpp.models.BuddyModel;
	import com.cleartext.ximpp.models.DatabaseModel;
	import com.cleartext.ximpp.models.SettingsModel;
	import com.cleartext.ximpp.models.XMPPModel;
	import com.cleartext.ximpp.models.types.ChatStateTypes;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.views.common.SearchBox;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.containers.ViewStack;
	import mx.core.Container;
	import mx.core.ScrollPolicy;
	import mx.effects.Move;
	import mx.events.CloseEvent;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	import mx.utils.StringUtil;
	
	public class MessageCanvas extends Canvas
	{
		[Autowire]
		[Bindable]
		public var appModel:ApplicationModel;
		
		[Autowire]
		[Bindable]
		public var xmpp:XMPPModel;
		
		[Autowire]
		[Bindable]
		public var settings:SettingsModel;
		
		[Autowire]
		[Bindable]
		public var buddies:BuddyModel;
		
		[Autowire]
		[Bindable]
		public var database:DatabaseModel;
			
		private static const ANIMATION_DURATION:Number = 350;

		private static const H_GAP:Number = 8;
		private static const SELECTOR_WIDTH:Number = 5;
		private static const TRIANGLE_HEIGHT:Number = 12;
		private static const TRIANGLE_WIDTH:Number = 16;
		private static const LIST_HEADER_HEIGHT:Number = 20;
		private static const SEARCH_BAR_HEIGHT:Number = 24;
		private static const SEARCH_BAR_BORDER:Number = 4;
		private static const SEARCH_BAR_WIDTH:Number = 220;
		private static const AVATAR_SIZE:Number = Constants.AVATAR_TAB_HEIGHT - TRIANGLE_HEIGHT - SELECTOR_WIDTH;
		
		private var avatars:ArrayCollection = new ArrayCollection();

		private var inputCanvas:InputCanvas;
		private var avatarCanvas:Canvas;
		private var searchBox:SearchBox;
		private var messageStack:ViewStack;
		private var customScroll:CustomScrollbar;

		private var searchTerms:Array = [];
		
		private var isTypingTimer:Timer;
		
		private var _index:int = 0;
		public function get index():int
		{
			return _index;
		}
		public function set index(value:int):void
		{
			_index = value;
			refreshIndex();
		}
		
		private function refreshIndex():void
		{
			if(_index >= avatars.length)
				_index = 0;
			else if(_index < 0)
				_index = Math.max(avatars.length -1, 0);
			
			var currentAvatar:AvatarTab = avatarByIndex(index);
			if(currentAvatar)
				setCurrentChat(currentAvatar.chat);
			else
				inputCanvas.buddy = null;
		}
		
		public function MessageCanvas()
		{
			super();
			
			horizontalScrollPolicy = "off";
			verticalScrollPolicy = "off";
			percentHeight = 100;
			percentWidth = 100;
			
			isTypingTimer = new Timer(3000, 2);
			isTypingTimer.addEventListener(TimerEvent.TIMER, isTimerTypingHandler);
			
			addEventListener(FlexEvent.CREATION_COMPLETE, 
				function():void
				{
					for each(var chat:Chat in appModel.chats)
						setCurrentChat(chat);
					appModel.chats.addEventListener(CollectionEvent.COLLECTION_CHANGE, chatsChangedHandler);
				});
		}
		
		private function chatsChangedHandler(event:CollectionEvent):void
		{
			for each(var chat:Chat in event.items)
			{
				if(event.kind == CollectionEventKind.ADD)
					setCurrentChat(chat);
				else if(event.kind == CollectionEventKind.REMOVE)
					removeChat(chat);
			}
		}
		
		public function sendMessage(messageString:String):void
		{
			var buddy:Buddy = avatarByIndex(index).buddy as Buddy;
			appModel.sendMessageTo(buddy, messageString);
		}
		
		public function numChats():int
		{
			return avatars.length;
		}
		
		private function avatarByIndex(i:int):AvatarTab
		{
			return (avatars.length > 0) ? avatars.getItemAt(i) as AvatarTab : null;
		}
		
		private function setCurrentChat(chat:Chat):void
		{
			if(!chat)
				return;
			
			inputCanvas.buddy = chat.buddy;

			// select the current one move and fade it or
			// create a new avatar
			var exists:Boolean = false;
			for(var i:int=0; i<avatars.length; i++)
			{
				var c:Chat = avatarByIndex(i).chat;
				setChatStateTo(c, ChatStateTypes.ACTIVE);
				if(c == chat)
				{
					_index = i;
					moveAvatar(index, 1);

					exists = true;
					
					for each(var s:Container in messageStack.getChildren())
					{
						if(s.data == chat)
						{
							messageStack.selectedChild = s;
							break;
						}
					}
				}
			}
			
			if(!exists)
			{
				chat.messages.filterFunction = filterMessages;
				setChatStateTo(chat, ChatStateTypes.ACTIVE);
				
				var avatar:AvatarTab = new AvatarTab();
				avatar.data = chat;
				avatar.addEventListener(MouseEvent.CLICK, avatarClickHandler, false, 0, true);
				avatar.width = AVATAR_SIZE;
				avatar.height = AVATAR_SIZE;
				avatar.border = false;
				avatar.toolTip = chat.buddy.nickName;
				avatar.addEventListener(CloseEvent.CLOSE, avatar_close);
				avatar.alpha = 0;
	
				avatars.addItemAt(avatar, index);
				moveAvatar(index, 1, false);
				avatarCanvas.addChildAt(avatar, 0);
				
				var sproutList:MessageSproutList = new MessageSproutList();
				sproutList.animate = settings.global.animateMessageList;
				sproutList.horizontalScrollPolicy = "off";
				sproutList.data = chat;
				messageStack.addChild(sproutList);
				messageStack.selectedChild = sproutList;
				
				chat.buddy.open = true;
			}
			
			chat.messages.refresh();
			
			// do all the other avatars
			var cursor:int = index+1;
			for(var j:int=1; j<avatars.length; j++)
			{
				if(cursor >= avatars.length)
					cursor = 0;
				
				// the last avatar needs to go to position 0
				moveAvatar(cursor, (j==avatars.length-1) ? 0 : j+1);
				cursor++;
			}
			
			customScroll.value = 0;
		}
		
		private function setChatStateTo(chat:Chat, newState:String, sendStanza:Boolean=true):void
		{
			if(chat.chatState != newState)
			{
				chat.chatState = newState;
				if(sendStanza && xmpp.connected && !chat.buddy.microBlogging)
					xmpp.sendMessage(chat.buddy.fullJid, null, null, 'chat', newState);
			}
		}
		
		private function avatar_close(event:CloseEvent):void
		{
			var avatar:AvatarTab = event.target as AvatarTab;
			avatar.chat.buddy.open = false;
			appModel.chats.removeItemAt(appModel.chats.getItemIndex(avatar.chat));
		}
				
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!inputCanvas)
			{
				inputCanvas = new InputCanvas();
				inputCanvas.addEventListener(KeyboardEvent.KEY_DOWN, input_keyDownHandler);
				inputCanvas.messageCanvas = this;
				addChild(inputCanvas);
			}
			
			if(!avatarCanvas)
			{
				avatarCanvas = new Canvas();
				avatarCanvas.horizontalScrollPolicy = ScrollPolicy.OFF;
				avatarCanvas.y = Constants.TOP_BAR_HEIGHT;
				avatarCanvas.clipContent = false;
				avatarCanvas.horizontalScrollPolicy = "off";
				avatarCanvas.verticalScrollPolicy = "off";
				addChild(avatarCanvas);
			}
			
			if(!customScroll)
			{
				customScroll = new CustomScrollbar();
				customScroll.addEventListener("scrollChanged", scrollChangedHandler);
				addChild(customScroll);
			}
			
			if(!searchBox)
			{
				searchBox = new SearchBox();
				searchBox.width = SEARCH_BAR_WIDTH;
				searchBox.height = SEARCH_BAR_HEIGHT;
				searchBox.borderAlpha = 0.5;
				searchBox.setConstraintValue("right", 23);
				searchBox.addEventListener(SearchBoxEvent.SEARCH, doSearch);
				searchBox.y = Constants.TOP_BAR_HEIGHT + Constants.AVATAR_TAB_HEIGHT - SEARCH_BAR_HEIGHT/2;
				addChild(searchBox);
			}
			
			if(!messageStack)
			{
				messageStack = new ViewStack();
				messageStack.setStyle("backgroundColor", 0xffffff);
				addChild(messageStack);
			}
		}
		
		private function input_keyDownHandler(event:KeyboardEvent):void
		{
			setChatStateTo(avatarByIndex(index).chat, ChatStateTypes.COMPOSING);
			isTypingTimer.reset();
			isTypingTimer.start();
		}
		
		private function isTimerTypingHandler(event:TimerEvent):void
		{
			var chat:Chat = avatarByIndex(index).chat;
			
			if(chat.chatState == ChatStateTypes.COMPOSING)
				setChatStateTo(chat, ChatStateTypes.PAUSED);
			else
				setChatStateTo(chat, ChatStateTypes.ACTIVE);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			customScroll.setRange(unscaledWidth, H_GAP + numChats() * (H_GAP + AVATAR_SIZE));
			customScroll.setActualSize(unscaledWidth - 216, 12);
			customScroll.move(200, Constants.TOP_BAR_HEIGHT - 6);
			
			inputCanvas.move(0, 0);
			inputCanvas.setActualSize(unscaledWidth, Constants.TOP_BAR_HEIGHT);
			
			messageStack.move(0, Constants.TOP_BAR_HEIGHT + Constants.AVATAR_TAB_HEIGHT + SEARCH_BAR_HEIGHT);
			messageStack.setActualSize(unscaledWidth, unscaledHeight - Constants.TOP_BAR_HEIGHT - Constants.AVATAR_TAB_HEIGHT - SEARCH_BAR_HEIGHT);
			
			var g:Graphics = avatarCanvas.graphics;
			g.clear();
			g.beginFill(0xffffff);
			var xVal:Number = AVATAR_SIZE + 2*H_GAP;
			var yVal:Number = 0;

			// draw triangle
			g.moveTo(xVal + SELECTOR_WIDTH + (AVATAR_SIZE - TRIANGLE_WIDTH)/2, yVal);
			g.lineTo(xVal + SELECTOR_WIDTH + (AVATAR_SIZE + TRIANGLE_WIDTH)/2, yVal);
			g.lineTo(xVal + SELECTOR_WIDTH + AVATAR_SIZE/2, TRIANGLE_HEIGHT-2 + yVal);
			g.lineTo(xVal + SELECTOR_WIDTH + (AVATAR_SIZE - TRIANGLE_WIDTH)/2, yVal);
			// draw outer box
			g.drawRect(xVal, TRIANGLE_HEIGHT + yVal, AVATAR_SIZE + 2*SELECTOR_WIDTH, AVATAR_SIZE + SELECTOR_WIDTH);
			// draw inner box
			g.drawRect(xVal + SELECTOR_WIDTH, TRIANGLE_HEIGHT + SELECTOR_WIDTH + yVal, AVATAR_SIZE, AVATAR_SIZE);
			
			g = graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRoundRect(
				unscaledWidth - SEARCH_BAR_WIDTH - 23 - SEARCH_BAR_BORDER,
				Constants.TOP_BAR_HEIGHT + Constants.AVATAR_TAB_HEIGHT - SEARCH_BAR_HEIGHT/2 - SEARCH_BAR_BORDER,
				SEARCH_BAR_WIDTH + 2*SEARCH_BAR_BORDER,
				SEARCH_BAR_HEIGHT + 2*SEARCH_BAR_BORDER,
				SEARCH_BAR_HEIGHT + SEARCH_BAR_BORDER,
				SEARCH_BAR_HEIGHT + SEARCH_BAR_BORDER);

			g.beginFill(0xffffff);
			g.drawRoundRect(
				0, Constants.TOP_BAR_HEIGHT + Constants.AVATAR_TAB_HEIGHT,
				unscaledWidth, LIST_HEADER_HEIGHT + 8,
				8, 8);

			var m:Matrix = new Matrix();
			m.createGradientBox(unscaledWidth, LIST_HEADER_HEIGHT, Math.PI/2, 0, Constants.TOP_BAR_HEIGHT + Constants.AVATAR_TAB_HEIGHT);
			g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xdedede], [0, 0.5], [95, 255], m); 
			g.drawRect(1, Constants.TOP_BAR_HEIGHT + Constants.AVATAR_TAB_HEIGHT, unscaledWidth-2, LIST_HEADER_HEIGHT);
		}
		
		private function doSearch(event:SearchBoxEvent):void
		{
			// get the search term, split it using one or more whitespace
			// refresh the message collection
			
			var searchString:String = event.searchString.toLocaleLowerCase();
			searchString = StringUtil.trim(searchString);
			searchTerms = searchString.split(/\s+/);
			avatarByIndex(index).chat.messages.refresh();
		}

		private function filterMessages(message:Message):Boolean
		{
			if(searchTerms.length == 0)
				return true;
			
			for each(var searchTerm:String in searchTerms)
			{
				if(message.mBlogSender)
				{
					if(message.mBlogSender.userName.toLowerCase().indexOf(searchTerm) != -1)
						return true;
					if(message.mBlogSender.displayName.toLowerCase().indexOf(searchTerm) != -1)
						return true;
				}
				if(message.plainMessage.toLocaleLowerCase().indexOf(searchTerm) != -1)
					return true;
			}
			return false;
		}
		
		private function avatarClickHandler(event:MouseEvent):void
		{
			setCurrentChat((event.currentTarget as AvatarTab).chat);
		}
		
		private function moveAvatar(avatarIndex:int, position:int, animate:Boolean=true):void
		{
			var avatar:AvatarTab = avatarByIndex(avatarIndex);
			
			avatar.selected = (position == 1);
	
			var newX:Number = (AVATAR_SIZE + H_GAP)*position + H_GAP;

			if(position == 1)
			{
				(avatar.buddy as Buddy).unreadMessageCount = 0;
				newX += SELECTOR_WIDTH;
			}
			else if(position >1)
				newX += 2*SELECTOR_WIDTH;

			var newY:Number = SELECTOR_WIDTH + TRIANGLE_HEIGHT;

			if(animate && (avatar.x != newX || avatar.y != newY))
			{
				var move:Move = new Move(avatar);
				move.duration = ANIMATION_DURATION;
				move.xTo = newX;
				move.yTo = newY;
				move.play();
			}
			else
			{
				avatar.move(newX, newY);
			}
		}
		
		private function removeChat(chat:Chat=null):void
		{
			if(avatars.length == 0)
				return;
			
			var avatarToRemove:AvatarTab;
			
			if(chat)
			{
				for each(var a:AvatarTab in avatars)
				{
					if(a.chat == chat)
					{
						avatarToRemove = a;
						break;
					}
				}
			}
			else
			{
				avatarToRemove = avatarByIndex(index);
			}
			
			if(!avatarToRemove)
				return;

			avatarCanvas.removeChild(avatarToRemove);
			avatars.removeItemAt(avatars.getItemIndex(avatarToRemove));

			for each(var s:Container in messageStack.getChildren())
			{
				if(s.data == avatarToRemove.chat)
				{
					messageStack.removeChild(s);
					break;
				}
			}

			// make sure index is valid and layout the avatars
			refreshIndex();
		}
		
		[Mediate(event="ChatEvent.SELECT_CHAT")]
		public function selectChatHandler(event:ChatEvent):void
		{
			setCurrentChat(event.chat);
		}
		
		private function scrollChangedHandler(event:Event):void
		{
			avatarCanvas.x = -customScroll.value* (numChats() * (H_GAP + AVATAR_SIZE) + H_GAP - width);
		}
	}
}