package com.cleartext.ximpp.models.valueObjects
{
	import mx.collections.ArrayCollection;
	
	public class ChatRoom extends BuddyBase
	{
		public function ChatRoom(jid:String)
		{
			super(jid);
		}
		
		private var _participants:ArrayCollection = new ArrayCollection();
		override public function get participants():ArrayCollection
		{
			return _participants;
		}
		
	}
}