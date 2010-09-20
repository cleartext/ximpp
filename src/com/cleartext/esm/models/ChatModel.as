package com.cleartext.esm.models
{
	import com.cleartext.esm.events.ChatEvent;
	import com.cleartext.esm.models.types.BuddyTypes;
	import com.cleartext.esm.models.valueObjects.Avatar;
	import com.cleartext.esm.models.valueObjects.Buddy;
	import com.cleartext.esm.models.valueObjects.BuddyGroup;
	import com.cleartext.esm.models.valueObjects.Chat;
	import com.cleartext.esm.models.valueObjects.ChatRoom;
	import com.cleartext.esm.models.valueObjects.Contact;
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
		public var buddies:ContactModel;
				
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
			getChat(event.contact, event.select);
		}
		
		public function getChat(ContactOrJid:Object, select:Boolean=false, type:String=BuddyTypes.BUDDY):Chat
		{
			var chat:Chat;

			if(ContactOrJid is String)
				chat = chatsByJid[ContactOrJid];
			else if(ContactOrJid is Contact)
				chat = chatsByJid[ContactOrJid.jid];
			else
				return null;
			
			if(!chat)
			{
				if(chats.length == 0)
					select = true;
				
				var contact:Contact = ContactOrJid as Contact;
				if(!contact)
				{
					var jid:String = ContactOrJid as String;
					switch(type)
					{
						case BuddyTypes.CHAT_ROOM :
							contact = new ChatRoom(jid);
							break;
						case BuddyTypes.GROUP :
							contact = new BuddyGroup(jid);
							buddies.addBuddy(contact);
							(contact as BuddyGroup).refresh(buddies);
							break;
						default :
							contact = new Buddy(jid);
							break;
					}
				}
				
				
				if((contact is ChatRoom) && !appModel.xmpp.connected)
				{
					return null;
				}

				chat = new Chat(contact);
				database.loadMessages(chat, !select);
				var index:int = 0;
				if(selectedChat)
				{
					index = chats.indexOf(selectedChat);
				}
				chats.splice(index, 0, chat);
				chatsByJid[contact.jid] = chat;
				contact.openTab = true;
				
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
		
		public function removeChat(contactOrJid:Object=null):void
		{
			var chat:Chat;
			var contact:Contact;

			if(!contactOrJid)
				chat = selectedChat;
			else if(contactOrJid is Contact)
				chat = chatsByJid[contactOrJid.jid];
			else if(contactOrJid is String)
				chat = chatsByJid[contactOrJid];
			
			if(!chat)
				return;

			contact = chat.contact;

			contact.openTab = false;
			var i:int = chats.indexOf(chat);
			chats.splice(i, 1);
			delete chatsByJid[contact.jid];

			if(chat == selectedChat)
			{
				if(chats.length == 0)
					_selectedChat = null;
				else
					_selectedChat = (i >= chats.length) ? chats[0] : chats[i];
			}
			dispatchEvent(new ChatEvent(ChatEvent.REMOVE_CHAT, chat, i));
			
			if(contact is ChatRoom)
			{
				appModel.chatRooms.leave(contact as ChatRoom);
			}
		}
		
		public function hasOpenChat(contact:Contact):Boolean
		{
			return chatsByJid.hasOwnProperty(contact.jid);
		}
		
		public function addMessage(contact:Contact, message:Message):void
		{
			if(chatsByJid.hasOwnProperty(contact.jid))
				getChat(contact).addMessage(message, contact.isMicroBlogging ? settings.global.numTimelineMessages : settings.global.numChatMessages);
			else if(contact.autoOpenTab)
				getChat(contact);
		}
	}
}