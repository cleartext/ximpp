package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.events.ChatEvent;
	import com.cleartext.ximpp.events.SearchBoxEvent;
	import com.cleartext.ximpp.models.ApplicationModel;
	import com.cleartext.ximpp.models.BuddyModel;
	import com.cleartext.ximpp.models.Constants;
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
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.utils.Timer;
	
	import mx.binding.utils.BindingUtils;
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

		private var searchString:String="";
		
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
			var chat:Chat = avatarByIndex(index).chat;
			chat.chatState = ChatStateTypes.ACTIVE;
			
			var buddiesToSendTo:Array;
			
			if(chat.buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
				buddiesToSendTo = buddies.microBloggingBuddies.toArray();
			else
				buddiesToSendTo = [chat.buddy];

			for each(var buddy:Buddy in buddiesToSendTo)
			{
				if(buddy.status.isOffline())
					continue;

				xmpp.sendMessage(buddy.fullJid, messageString);
				
				var message:Message = new Message();
				message.sender = settings.userAccount.jid;
				message.recipient = buddy.jid;
				message.body = messageString;
				message.timestamp = new Date();
				
				var c:Chat = appModel.getChat(buddy);
				c.messages.addItemAt(message,0);
				
				if(buddy.microBlogging)
				{
					c = appModel.getChat(Buddy.ALL_MICRO_BLOGGING_BUDDY);
					c.messages.addItemAt(message,0);
				}

				database.saveMessage(message);
			}
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
				BindingUtils.bindProperty(sproutList, "animate", settings.global, "animateMessageList");
				sproutList.horizontalScrollPolicy = "off";
				sproutList.data = chat;
				messageStack.addChild(sproutList);
				messageStack.selectedChild = sproutList;
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
		}
		
		private function setChatStateTo(chat:Chat, newState:String, sendStanza:Boolean=true):void
		{
			if(chat.chatState != newState)
			{
				chat.chatState = newState;
				if(sendStanza && xmpp.connected)
					xmpp.sendMessage(chat.buddy.fullJid, null, null, 'chat', newState);
			}
		}
		
		private function avatar_close(event:CloseEvent):void
		{
			var avatar:AvatarTab = event.target as AvatarTab;
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
				addChild(avatarCanvas);
			}
			
			if(!searchBox)
			{
				searchBox = new SearchBox();
				searchBox.width = SEARCH_BAR_WIDTH;
				searchBox.height = SEARCH_BAR_HEIGHT;
				searchBox.borderAlpha = 0.5;
				searchBox.setConstraintValue("right", 23);
				searchBox.addEventListener(SearchBoxEvent.SEARCH, doSearch);
				searchBox.y = Constants.TOP_BAR_HEIGHT + TRIANGLE_HEIGHT + SELECTOR_WIDTH + AVATAR_SIZE - SEARCH_BAR_HEIGHT/2;
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
			
			inputCanvas.move(0, 0);
			inputCanvas.setActualSize(unscaledWidth, Constants.TOP_BAR_HEIGHT);
			
			avatarCanvas.move(0, Constants.TOP_BAR_HEIGHT);
			avatarCanvas.setActualSize(unscaledWidth, AVATAR_SIZE + SELECTOR_WIDTH + TRIANGLE_HEIGHT);

			messageStack.move(0, Constants.TOP_BAR_HEIGHT + SEARCH_BAR_HEIGHT + avatarCanvas.height);
			messageStack.setActualSize(unscaledWidth, unscaledHeight - Constants.TOP_BAR_HEIGHT - avatarCanvas.height - SEARCH_BAR_HEIGHT);
			
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xffffff);
			var xVal:Number = AVATAR_SIZE + 2*H_GAP;
			var yVal:Number = Constants.TOP_BAR_HEIGHT;
			// draw triangle
			g.moveTo(xVal + SELECTOR_WIDTH + (AVATAR_SIZE - TRIANGLE_WIDTH)/2, yVal);
			g.lineTo(xVal + SELECTOR_WIDTH + (AVATAR_SIZE + TRIANGLE_WIDTH)/2, yVal);
			g.lineTo(xVal + SELECTOR_WIDTH + AVATAR_SIZE/2, TRIANGLE_HEIGHT-2 + yVal);
			g.lineTo(xVal + SELECTOR_WIDTH + (AVATAR_SIZE - TRIANGLE_WIDTH)/2, yVal);
			// draw outer box
			g.drawRect(xVal, TRIANGLE_HEIGHT + yVal, AVATAR_SIZE + 2*SELECTOR_WIDTH, AVATAR_SIZE + SELECTOR_WIDTH);
			// draw inner box
			g.drawRect(xVal + SELECTOR_WIDTH, TRIANGLE_HEIGHT + SELECTOR_WIDTH + yVal, AVATAR_SIZE, AVATAR_SIZE);

			g.beginFill(0xffffff);
			g.drawRoundRect(
				unscaledWidth - SEARCH_BAR_WIDTH - 23 - SEARCH_BAR_BORDER,
				Constants.TOP_BAR_HEIGHT+TRIANGLE_HEIGHT + SELECTOR_WIDTH + AVATAR_SIZE - SEARCH_BAR_HEIGHT/2 - SEARCH_BAR_BORDER,
				SEARCH_BAR_WIDTH + 2*SEARCH_BAR_BORDER,
				SEARCH_BAR_HEIGHT + 2*SEARCH_BAR_BORDER,
				SEARCH_BAR_HEIGHT + SEARCH_BAR_BORDER,
				SEARCH_BAR_HEIGHT + SEARCH_BAR_BORDER);

			g.beginFill(0xffffff);
			g.drawRoundRect(
				0,
				Constants.TOP_BAR_HEIGHT+TRIANGLE_HEIGHT+SELECTOR_WIDTH+AVATAR_SIZE,
				unscaledWidth,
				LIST_HEADER_HEIGHT + 8,
				8, 8);

			var m:Matrix = new Matrix();
			m.createGradientBox(unscaledWidth, LIST_HEADER_HEIGHT, Math.PI/2, 0, Constants.TOP_BAR_HEIGHT+TRIANGLE_HEIGHT+SELECTOR_WIDTH+AVATAR_SIZE);
			g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xdedede], [0, 0.5], [95, 255], m); 
			g.drawRect(1, Constants.TOP_BAR_HEIGHT+TRIANGLE_HEIGHT+SELECTOR_WIDTH+AVATAR_SIZE , unscaledWidth-2, LIST_HEADER_HEIGHT);
		}
		
		private function doSearch(event:SearchBoxEvent):void
		{
			searchString = event.searchString;
			avatarByIndex(index).chat.messages.refresh();
		}

		private function filterMessages(message:Message):Boolean
		{
			return message.body.toLowerCase().indexOf(searchString.toLowerCase()) != -1;
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
				avatar.buddy.unreadMessageCount = 0;
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
	}
}