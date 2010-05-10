package com.cleartext.ximpp.events
{
	import flash.events.Event;
	
	public class BuddyRequestEvent extends Event
	{
		public static const BUDDY_REQUEST_CHANGED:String = "buddyRequestChanged";
		
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