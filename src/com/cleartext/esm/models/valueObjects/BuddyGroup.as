package com.cleartext.esm.models.valueObjects
{
	import com.cleartext.esm.models.ContactModel;
	
	import flash.sampler.DeleteObjectSample;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	
	public class BuddyGroup extends Contact
	{
		public function BuddyGroup(jid:String)
		{
			super(jid);
			
			_participants = new ArrayCollection();
			
			var sort:Sort = new Sort();
			sort.compareFunction = statusSort;
			participants.sort = sort;
			participants.refresh();
		}

		public function refresh(buddies:ContactModel):void
		{
			var contact:Contact;
			var bArray:Array = buddies.getBuddiesByGroup(jid);
			
			var buddiesToRemove:Dictionary = new Dictionary();
			
			for each(contact in participants)
				buddiesToRemove[contact.jid] = contact;
			
			for each(contact in bArray)
			{
				if(buddiesToRemove.hasOwnProperty(contact.jid))
					delete buddiesToRemove[contact.jid];
				else
					participants.addItem(contact);
			}
			
			for each(contact in buddiesToRemove)
			{
				var i:int = participants.getItemIndex(contact);
				participants.removeItemAt(i);
			}
			
			participants.refresh();
		}
		
		private function statusSort(c1:Contact, c2:Contact, fields:Object=null):int
		{
			var statusCompare:int = clamp(c1.statusSortIndex- c2.statusSortIndex);
			if(statusCompare != 0)
				return statusCompare;
			return clamp(c1.nickname.localeCompare(c2.nickname));
		}
		
		private function clamp(value:Number):int
		{
			if(value == 0)
				return 0;
			return (value > 0) ? 1 : -1;
		}
		
		private var _participants:ArrayCollection;
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
				new DatabaseValue("customStatus", customStatus),
				new DatabaseValue("openTab", openTab),
				new DatabaseValue("autoOpenTab", autoOpenTab),
				new DatabaseValue("unreadMessages", unreadMessages),
				new DatabaseValue("buddyType","group")
				];
		}
	}
}