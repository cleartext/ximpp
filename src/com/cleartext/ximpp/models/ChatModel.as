package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.ChatEvent;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.Message;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;

	public class ChatModel extends EventDispatcher
	{
		[Autowire]
		public var appModel:ApplicationModel;

		[Autowire]
		public var database:DatabaseModel;
		
		[Autowire]
		public var settings:SettingsModel;
		
		public var chatsByJid:Dictionary;
		
		private var _chats:ArrayCollection;
		public function get chats():ArrayCollection
		{
			return _chats;
		}
		
		private var _selectedChat:Chat;
		[Bindable (event="selectChat")]
		public function get selectedChat():Chat
		{
			return _selectedChat;
		}
		public function set selectedChat(value:Chat):void
		{
			if(selectedChat != value)
			{
				_selectedChat = value;
				dispatchEvent(new ChatEvent(ChatEvent.SELECT_CHAT));
			}
		}
		
		public function ChatModel()
		{
			super();
			
			_chats = new ArrayCollection();
			chatsByJid = new Dictionary();
		}
		
		public function getChat(buddy:Buddy, select:Boolean=false):Chat
		{
			if(!buddy)
				return null;
			
			var chat:Chat = chatsByJid[buddy.jid];
			
			if(!chat)
			{
				chat = new Chat(buddy);
				chat.messages = database.loadMessages(buddy);
				var index:int = chats.length;
				if(selectedChat)
				{
					index = chats.getItemIndex(selectedChat) - 1;
					if(index < 0)
						index = chats.length;
				}
				chats.addItemAt(chat, index);
				chatsByJid[buddy.jid] = chat;
				buddy.open = true;
			}
			
			if(select)
				selectedChat = chat;
				
			return chat;
		}
		
		public function removeChat(buddy:Buddy):void
		{
			var chat:Chat = chatsByJid[buddy.jid];
			
			if(chat)
			{
				buddy.open = false;
				var i:int = chats.getItemIndex(chat);
				chats.removeItemAt(i);
				delete chatsByJid[buddy.jid];
			}
		}
		
		public function addMessage(buddy:Buddy, message:Message):void
		{
			var limit:int = (buddy.microBlogging) ? settings.global.numTimelineMessages : settings.global.numChatMessages;			
			
			getChat(buddy).addMessage(message, limit);
				
			if(buddy.microBlogging)
				getChat(Buddy.ALL_MICRO_BLOGGING_BUDDY).addMessage(message, limit);
		}
		
	}
}