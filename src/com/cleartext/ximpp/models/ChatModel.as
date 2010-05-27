package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.ChatEvent;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.models.valueObjects.Status;
	
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
		
		public function getChat(buddyOrJid:Object, select:Boolean=false, type:String=Buddy.BUDDY):Chat
		{
			var chat:Chat;

			if(buddyOrJid is String)
				chat = chatsByJid[buddyOrJid];
			else if(buddyOrJid is Buddy)
				chat = chatsByJid[buddyOrJid.jid];
			else
				return null;
			
			if(!chat)
			{
				if(chats.length == 0)
					select = true;
				
				var buddy:Buddy = buddyOrJid as Buddy;
				if(!buddy)
				{
					buddy = new Buddy(buddyOrJid as String);
					
					switch(type)
					{
						case Buddy.CHAT_ROOM :
							buddy.status.value = Status.AVAILABLE;
							buddy.isChatRoom = true;
							break;
						case Buddy.GROUP :
							buddy.isGroup = true;
							buddy.status.value = Status.AVAILABLE;
							break;
					}
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
		
		public function removeChat(buddy:Buddy=null):void
		{
			var chat:Chat;

			if(!buddy)
				chat = selectedChat;
			else
				chat = chatsByJid[buddy.jid];
			
			if(chat)
			{
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
				
				if(buddy.isChatRoom)
				{
					appModel.xmpp.leaveChatRoom(buddy.jid);
				}
			}
		}
		
		public function addMessage(buddy:Buddy, message:Message):void
		{
			var limit:int = (buddy.isMicroBlogging) ? settings.global.numTimelineMessages : settings.global.numChatMessages;			
			
			if(buddy.autoOpenTab || chatsByJid.hasOwnProperty(buddy.jid))
				getChat(buddy).addMessage(message, limit);
				
			if(buddy.isMicroBlogging)
				getChat(Buddy.ALL_MICRO_BLOGGING_BUDDY).addMessage(message, limit);
		}
		
	}
}