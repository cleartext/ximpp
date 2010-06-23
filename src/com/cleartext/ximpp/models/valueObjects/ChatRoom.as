package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.ChatEvent;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	import org.swizframework.Swiz;
	
	public class ChatRoom extends BuddyBase
	{
		public function ChatRoom(jid:String)
		{
			super(jid);
		}
		
		public var ourNickname:String;
		public var password:String;
		
		private var _participants:ArrayCollection = new ArrayCollection();
		override public function get participants():ArrayCollection
		{
			return _participants;
		}
		
		public function setPresence(jid:String, statusType:String, nickname:String, oldNickname:String=""):void
		{
			var participant:ChatRoomParticipant;
			
			if(nickname == ourNickname)
			{
				status.setFromStanzaType(statusType);
				
				if(!status.isOffline())
				{
					Swiz.dispatchEvent(new ChatEvent(ChatEvent.OPEN_ME, null, -1, true, this)); 
				}
				return;
			}
			
			for each(participant in participants)
			{
				if((oldNickname && participant.nickname == oldNickname) ||
					(jid && participant.jid == jid))
				{
					if(statusType == Status.UNAVAILABLE)
						participants.removeItemAt(participants.getItemIndex(participant));
						return;
					
					participant.status.setFromStanzaType(statusType);
					participant.nickname = nickname;
					participants.dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.REFRESH));
					return;
				}
			}
			
			if((jid || nickname) && statusType != Status.UNAVAILABLE)
			{
				participant = new ChatRoomParticipant();
				participant.jid = jid;
				participant.status.setFromStanzaType(statusType);
				participant.nickname = nickname;
				participants.addItem(participant);
			}
		}

		override public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("jid", jid),
				new DatabaseValue("nickname", getNickname()),
				new DatabaseValue("groups", ourNickname + "," + password),
				new DatabaseValue("lastSeen", lastSeen),
				new DatabaseValue("subscription", ""),
				new DatabaseValue("avatar", avatarString),
				new DatabaseValue("customStatus", customStatus),
				new DatabaseValue("avatarHash", avatarHash),
				new DatabaseValue("openTab", openTab),
				new DatabaseValue("autoOpenTab", autoOpenTab),
				new DatabaseValue("unreadMessages", unreadMessages),
				new DatabaseValue("buddyType","chatRoom")
			];
		}
		
	}
}