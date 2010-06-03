package com.cleartext.ximpp.events
{
	import flash.events.Event;
	
	public class BuddyRequestEvent extends Event
	{
		public static const BUDDY_REQUEST_CHANGED:String = "buddyRequestChanged";
		public static const NEW_REQUEST:String = "newRequest";
		public static const REMOVE_REQUEST:String = "removeRequest";
		
		public function BuddyRequestEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new BuddyRequestEvent(type, bubbles, cancelable);
		}

	}
}