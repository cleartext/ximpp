package com.cleartext.ximpp.events
{
	import flash.events.Event;

	public class BuddyEvent extends Event
	{
		public static const CUSTOM_STATUS_CHANGED:String = "customStatusChanged";
		
		public function BuddyEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}