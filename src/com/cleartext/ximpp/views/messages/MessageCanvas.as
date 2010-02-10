package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.events.ChatEvent;
	import com.cleartext.ximpp.models.ApplicationModel;
	import com.cleartext.ximpp.models.Constants;
	import com.cleartext.ximpp.models.DatabaseModel;
	import com.cleartext.ximpp.models.SettingsModel;
	import com.cleartext.ximpp.models.XMPPModel;
	import com.cleartext.ximpp.models.AvatarUtils;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.views.common.Avatar;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.containers.ViewStack;
	import mx.core.Container;
	import mx.core.ScrollPolicy;
	import mx.effects.Fade;
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
		public var database:DatabaseModel;
			
		private static const ANIMATION_DURATION:Number = 350;

		private static const H_GAP:Number = 8;
		private static const SELECTOR_WIDTH:Number = 5;
		private static const TRIANGLE_HEIGHT:Number = 12;
		private static const TRIANGLE_WIDTH:Number = 16;
		private static const SEARCH_BAR_HEIGHT:Number = 38;
		private static const AVATAR_SIZE:Number = Constants.AVATAR_TAB_HEIGHT - TRIANGLE_HEIGHT - SELECTOR_WIDTH;
		
		private static const SELECTED_ALPHA:Number = 1.0;
		private static const OVER_ALPHA:Number = 1.0;
		private static const OUT_ALPHA:Number = 0.7;
		
		private var avatars:ArrayCollection = new ArrayCollection();

		private var inputCanvas:InputCanvas;
		private var avatarCanvas:Canvas;
		private var selector:Sprite;
		private var spacerCanvas:SpacerCanvas;
		private var messageStack:ViewStack;

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
			
			var currentAvatar:Avatar = avatarByIndex(index);
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
			
			xmpp.sendMessage(chat.buddy.fullJid, messageString);
			
			var message:Message = new Message();
			message.sender = settings.userAccount.jid;
			message.recipient = chat.buddy.jid;
			message.body = messageString;
			message.timestamp = new Date();
			
			chat.messages.addItemAt(message,0);
			database.saveMessage(message);
		}
		
		public function numChats():int
		{
			return avatars.length;
		}
		
		private function avatarByIndex(i:int):Avatar
		{
			return (avatars.length > 0) ? avatars.getItemAt(i) as Avatar : null;
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
				if(avatarByIndex(i).chat == chat)
				{
					_index = i;
					moveAvatar(index, 1, SELECTED_ALPHA);
					exists = true;
					
					for each(var s:Container in messageStack.getChildren())
					{
						if(s.data == chat)
						{
							messageStack.selectedChild = s;
							break;
						}
					}
					break;
				}
			}
			
			if(!exists)
			{
				var avatar:Avatar = new Avatar();
				avatar.data = chat;
				avatar.addEventListener(MouseEvent.CLICK, avatarClickHandler, false, 0, true);
				avatar.width = AVATAR_SIZE;
				avatar.height = AVATAR_SIZE;
				avatar.border = false;
				avatar.toolTip = chat.buddy.nickName;
				avatar.addEventListener(MouseEvent.ROLL_OVER, avatar_rollOver);
				avatar.addEventListener(MouseEvent.ROLL_OUT, avatar_rollOut); 
				avatar.alpha = 0;
	
				avatars.addItemAt(avatar, index);
				moveAvatar(index, 1, SELECTED_ALPHA, false);
				avatarCanvas.addChildAt(avatar, 0);
					
				var sproutList:MessageSproutList = new MessageSproutList();
				sproutList.horizontalScrollPolicy = "off";
				sproutList.data = chat;
				messageStack.addChild(sproutList);
				messageStack.selectedChild = sproutList;
			}
			
			// do all the other avatars
			var cursor:int = index+1;
			for(var j:int=1; j<avatars.length; j++)
			{
				if(cursor >= avatars.length)
					cursor = 0;
				
				// the last avatar needs to go to position 0
				moveAvatar(cursor, (j==avatars.length-1) ? 0 : j+1, OUT_ALPHA);
				cursor++;
			}
		}
		
		private function avatar_rollOver(event:MouseEvent):void
		{
			var avatar:Avatar = event.target as Avatar;
			if(avatarByIndex(index) != avatar)
				avatar.alpha = OVER_ALPHA;
		}
		
		private function avatar_rollOut(event:MouseEvent):void
		{
			var avatar:Avatar = event.target as Avatar;
			if(avatarByIndex(index) != avatar)
				avatar.alpha = OUT_ALPHA;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!inputCanvas)
			{
				inputCanvas = new InputCanvas();
				inputCanvas.messageCanvas = this;
				addChild(inputCanvas);
			}
			
			if(!avatarCanvas)
			{
				avatarCanvas = new Canvas();
				avatarCanvas.horizontalScrollPolicy = ScrollPolicy.OFF;
				addChild(avatarCanvas);
			}
			
			if(!spacerCanvas)
			{
				spacerCanvas = new SpacerCanvas();
				spacerCanvas.addEventListener(CloseEvent.CLOSE,
					function():void
					{
						var avatarToRemove:Avatar = avatarByIndex(index);
						if(avatarToRemove)
							appModel.chats.removeItemAt(appModel.chats.getItemIndex(avatarToRemove.chat));
					});
				addChild(spacerCanvas);
			}
			
			if(!messageStack)
			{
				messageStack = new ViewStack();
				messageStack.setStyle("backgroundColor", 0xffffff);
				addChild(messageStack);
			}

			if(!selector)
			{
				selector = new Sprite();
				rawChildren.addChild(selector);
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			inputCanvas.move(0, 0);
			inputCanvas.setActualSize(unscaledWidth, Constants.TOP_BAR_HEIGHT);
			
			avatarCanvas.move(0, Constants.TOP_BAR_HEIGHT);
			avatarCanvas.setActualSize(unscaledWidth, AVATAR_SIZE + SELECTOR_WIDTH + TRIANGLE_HEIGHT);
			
			spacerCanvas.move(0, Constants.TOP_BAR_HEIGHT +TRIANGLE_HEIGHT + SELECTOR_WIDTH + AVATAR_SIZE);
			spacerCanvas.setActualSize(unscaledWidth, SEARCH_BAR_HEIGHT);

			messageStack.move(0, Constants.TOP_BAR_HEIGHT + SEARCH_BAR_HEIGHT + avatarCanvas.height);
			messageStack.setActualSize(unscaledWidth, unscaledHeight - Constants.TOP_BAR_HEIGHT - avatarCanvas.height - SEARCH_BAR_HEIGHT);
			
			var g:Graphics = selector.graphics;
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
		}
		
		private function avatarClickHandler(event:MouseEvent):void
		{
			setCurrentChat((event.target as Avatar).chat);
		}
		
		private function moveAvatar(avatarIndex:int, position:int, newAlpha:Number=-1, animate:Boolean=true):void
		{
			var avatar:Avatar = avatarByIndex(avatarIndex);
			
			if(newAlpha != -1 && newAlpha != avatar.alpha)
			{
				var fade:Fade = new Fade(avatar);
				fade.alphaFrom = avatar.alpha;
				fade.alphaTo = newAlpha;
				fade.duration = ANIMATION_DURATION;
				fade.play();
			}

			var newX:Number = (AVATAR_SIZE + H_GAP)*position + H_GAP;

			if(position == 1)
				newX += SELECTOR_WIDTH;
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
			
			var avatarToRemove:Avatar;
			
			if(chat)
			{
				for each(var a:Avatar in avatars)
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