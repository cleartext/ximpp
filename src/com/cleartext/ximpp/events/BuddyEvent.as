package com.cleartext.ximpp.events
{
	import flash.events.Event;

	public class BuddyEvent extends Event
	{
		public static const EDIT_BUDDY:String = "editBuddy";
		public static const DELETE_BUDDY:String = "deleteBuddy";
		public static const CHANGED:String = "buddyChanged";
		
		public function BuddyEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new BuddyEvent(type, bubbles, cancelable);
		}
		
	}
}