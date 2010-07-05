package com.cleartext.esm.models
{
	import com.cleartext.esm.events.ChatRoomEvent;
	import com.cleartext.esm.models.valueObjects.ChatRoom;
	import com.cleartext.esm.models.valueObjects.IBuddy;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;

	public class ChatRoomModel extends EventDispatcher
	{
		[Autowire]
		public var appModel:ApplicationModel;
		
		private function get xmpp():XMPPModel
		{
			return appModel.xmpp;
		}
		
		private function get buddies():BuddyModel
		{
			return appModel.buddies;
		}
		
		public function ChatRoomModel(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function join(roomJid:String, nickname:String, password:String):void
		{
			var buddy:IBuddy = buddies.getBuddyByJid(roomJid);
			var chatRoom:ChatRoom = buddy as ChatRoom;

			if(buddy && !chatRoom)
			{
				throw Error("that jid already exists as a buddy: can not create as chat room.");
			}
			else if(!chatRoom)
			{
				chatRoom = new ChatRoom(roomJid);
			}
			
			chatRoom.ourNickname = nickname;
			chatRoom.password = password;
			
			buddies.addBuddy(chatRoom);
			xmpp.joinChatRoom(roomJid, nickname, password);
		}
		
		public function leave(chatRoom:ChatRoom):void
		{
			if(!chatRoom.status.isOffline())
				xmpp.leaveChatRoom(chatRoom.jid, chatRoom.ourNickname);

			chatRoom.participants.removeAll();
		}
	}
}