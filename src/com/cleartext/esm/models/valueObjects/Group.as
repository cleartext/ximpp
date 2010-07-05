package com.cleartext.esm.models.valueObjects
{
	import com.cleartext.esm.models.BuddyModel;
	
	import flash.sampler.DeleteObjectSample;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	
	public class Group extends BuddyBase
	{
		public function Group(jid:String)
		{
			super(jid);
			
			_participants = new ArrayCollection();
			
			var sort:Sort = new Sort();
			sort.compareFunction = statusSort;
			participants.sort = sort;
			participants.refresh();
		}

		public function refresh(buddies:BuddyModel):void
		{
			var b:IBuddy;
			var bArray:Array = buddies.getBuddiesByGroup(jid);
			
			var buddiesToRemove:Dictionary = new Dictionary();
			
			for each(b in participants)
				buddiesToRemove[b.jid] = b;
			
			for each(b in bArray)
			{
				if(buddiesToRemove.hasOwnProperty(b.jid))
					delete buddiesToRemove[b.jid];
				else
					participants.addItem(b);
			}
			
			for each(b in buddiesToRemove)
			{
				var i:int = participants.getItemIndex(b);
				participants.removeItemAt(i);
			}
			
			participants.refresh();
			
//			_participants = buddies.getBuddiesByGroup(jid);
//			var tmp:Array = new Array();
//			for each(var b:IBuddy in buddies.getBuddiesByGroup(jid))
//			{
//				if(!participants.contains(b))
//				{
//					
//				}
//				tmp.push(b.jid);
//			}
//		
//			for(var i:int=participants.length-1; i>=0; i--)
//			{
//				var index:int = tmp.indexOf(participants.getItemAt(i));
//				if(index == -1)
//					participants.removeItemAt(i);
//				else
//					tmp.splice(index, 1);
//			}
//			
//			while(tmp.length > 0)
//			{
//				participants.addItem(tmp.pop());
//			}
		}
		
		private function statusSort(b1:IBuddy, b2:IBuddy, fields:Object=null):int
		{
			var statusCompare:int = clamp(b1.statusSortIndex- b2.statusSortIndex);
			if(statusCompare != 0)
				return statusCompare;
			return clamp(b1.nickname.localeCompare(b2.nickname));
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