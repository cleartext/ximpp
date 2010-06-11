package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.BuddyModelEvent;
	import com.cleartext.ximpp.models.BuddyModel;
	
	import mx.collections.ArrayCollection;
	
	public class Group extends BuddyBase
	{
		private var buddies:BuddyModel;
		
		public function Group(jid:String, buddies:BuddyModel)
		{
			super(jid);
			this.buddies = buddies;
			
			buddies.addEventListener(BuddyModelEvent.REFRESH, dispatchEvent);
		}
		
		override public function get participants():ArrayCollection
		{
			return new ArrayCollection(buddies.getBuddiesByGroup(jid));
		}
	}
}