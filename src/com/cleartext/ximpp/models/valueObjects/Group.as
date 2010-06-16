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
			
			buddies.addEventListener(BuddyModelEvent.REFRESH, refreshHandler);
			
			refreshHandler(null);
		}
		
		private function refreshHandler(event:BuddyModelEvent):void
		{
			var tmp:Array = new Array();
			for each(var b:Buddy in buddies.getBuddiesByGroup(jid))
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
	}
}