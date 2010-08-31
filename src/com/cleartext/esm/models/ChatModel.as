package com.cleartext.esm.models
{
	import com.cleartext.esm.events.ChatEvent;
	import com.cleartext.esm.models.types.BuddyTypes;
	import com.cleartext.esm.models.valueObjects.Avatar;
	import com.cleartext.esm.models.valueObjects.Buddy;
	import com.cleartext.esm.models.valueObjects.BuddyGroup;
	import com.cleartext.esm.models.valueObjects.Chat;
	import com.cleartext.esm.models.valueObjects.ChatRoom;
	import com.cleartext.esm.models.valueObjects.IBuddy;
	import com.cleartext.esm.models.valueObjects.Message;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	public class ChatModel extends EventDispatcher
	{
		[Autowire]
		public var appModel:ApplicationModel;

		[Autowire]
		public var database:DatabaseModel;
		
		[Autowire]
		public var settings:SettingsModel;
		
		[Autowire]
		public var buddies:BuddyModel;
				
		[Autowire]
		public var avatarModel:AvatarModel;
				
		public var chatsByJid:Dictionary;
		
		private var chats:Array;
		
		private var _selectedChat:Chat;
		public function get selectedChat():Chat
		{
			return _selectedChat;
		}
		
		public function get selectedIndex():int
		{	
			return chats.indexOf(selectedChat);
		}
		
		public function ChatModel()
		{
			super();
			
			chats = new Array();
			chatsByJid = new Dictionary();
		}
		
		[Mediate(event="ChatEvent.OPEN_ME")]
		public function openChatHandler(event:ChatEvent):void
		{
			getChat(event.buddy, event.select);
		}
		
		public function getChat(buddyOrJid:Object, select:Boolean=false, type:String=BuddyTypes.BUDDY):Chat
		{
			var chat:Chat;

			if(buddyOrJid is String)
				chat = chatsByJid[buddyOrJid];
			else if(buddyOrJid is IBuddy)
				chat = chatsByJid[buddyOrJid.jid];
			else
				return null;
			
			if(!chat)
			{
				if(chats.length == 0)
					select = true;
				
				var buddy:IBuddy = buddyOrJid as IBuddy;
				if(!buddy)
				{
					var jid:String = buddyOrJid as String;
					switch(type)
					{
						case BuddyTypes.CHAT_ROOM :
							buddy = new ChatRoom(jid);
							break;
						case BuddyTypes.GROUP :
							buddy = new BuddyGroup(jid);
							buddies.addBuddy(buddy);
							(buddy as BuddyGroup).refresh(buddies);
							break;
						default :
							buddy = new Buddy(jid);
							break;
					}
				}
				
				
				if((buddy is ChatRoom) && !appModel.xmpp.connected)
				{
					return null;
				}

				chat = new Chat(buddy);
				database.loadMessages(chat, !select);
				var index:int = 0;
				if(selectedChat)
				{
					index = chats.indexOf(selectedChat);
				}
				chats.splice(index, 0, chat);
				chatsByJid[buddy.jid] = chat;
				buddy.openTab = true;
				
				if(select)
					_selectedChat = chat;
				else
					appModel.soundColor.play(SoundAndColorModel.NEW_CONVERSATION);
				
				dispatchEvent(new ChatEvent(ChatEvent.ADD_CHAT, chat, index, select));
			}
			else if(select && selectedChat != chat)
			{
				_selectedChat = chat;
				dispatchEvent(new ChatEvent(ChatEvent.SELECT_CHAT));
			}

			return chat;
		}
		
		public function removeChat(buddyOrJid:Object=null):void
		{
			var chat:Chat;
			var buddy:IBuddy;

			if(!buddyOrJid)
				chat = selectedChat;
			else if(buddyOrJid is IBuddy)
				chat = chatsByJid[buddyOrJid.jid];
			else if(buddyOrJid is String)
				chat = chatsByJid[buddyOrJid];
			
			if(!chat)
				return;

			buddy = chat.buddy;

			buddy.openTab = false;
			var i:int = chats.indexOf(chat);
			chats.splice(i, 1);
			delete chatsByJid[buddy.jid];

			if(chat == selectedChat)
			{
				if(chats.length == 0)
					_selectedChat = null;
				else
					_selectedChat = (i >= chats.length) ? chats[0] : chats[i];
			}
			dispatchEvent(new ChatEvent(ChatEvent.REMOVE_CHAT, chat, i));
			
			if(buddy is ChatRoom)
			{
				appModel.chatRooms.leave(buddy as ChatRoom);
			}
		}
		
		public function hasOpenChat(buddy:IBuddy):Boolean
		{
			return chatsByJid.hasOwnProperty(buddy.jid);
		}
		
		public function addMessage(buddy:IBuddy, message:Message):void
		{
			if(chatsByJid.hasOwnProperty(buddy.jid))
				getChat(buddy).addMessage(message, buddy.isMicroBlogging ? settings.global.numTimelineMessages : settings.global.numChatMessages);
			else if(buddy.autoOpenTab)
				getChat(buddy);
		}
	}
}