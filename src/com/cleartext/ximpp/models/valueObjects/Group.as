package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.models.BuddyModel;
	
	import mx.collections.ArrayCollection;
	
	public class Group extends BuddyBase
	{
		public function Group(jid:String)
		{
			super(jid);
		}

		public function refresh(buddies:BuddyModel):void
		{
			var tmp:Array = new Array();
			for each(var b:IBuddy in buddies.getBuddiesByGroup(jid))
			{
				tmp.push(b.jid);
			}
		
			for(var i:int=participants.length-1; i>=0; i--)
			{
				var index:int = tmp.indexOf(participants.getItemAt(i));
				if(index == -1)
					participants.removeItemAt(i);
				else
					tmp.splice(index, 1);
			}
			
			while(tmp.length > 0)
			{
				participants.addItem(tmp.pop());
			}
		}
		
		private var _participants:ArrayCollection = new ArrayCollection();
		override public function get participants():ArrayCollection
		{
			return _participants;
		}
		
		override public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("jid", jid),
				new DatabaseValue("nickname", getNickname()),
				new DatabaseValue("groups", ""),
				new DatabaseValue("lastSeen", lastSeen),
				new DatabaseValue("subscription", ""),
				new DatabaseValue("avatar", avatarString),
				new DatabaseValue("customStatus", customStatus),
				new DatabaseValue("avatarHash", avatarHash),
				new DatabaseValue("openTab", openTab),
				new DatabaseValue("autoOpenTab", autoOpenTab),
				new DatabaseValue("unreadMessages", unreadMessages),
				new DatabaseValue("buddyType","group")
				];
		}
	}
}