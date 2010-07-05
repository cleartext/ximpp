package com.cleartext.esm.events
{
	import flash.events.Event;

	public class BuddyModelEvent extends Event
	{
		public static const FILTER_CHANGED:String = "filterChanged";
		public static const REFRESH:String = "refresh";
		
		public function BuddyModelEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}

		override public function clone():Event
		{
			return new BuddyModelEvent(type, bubbles, cancelable);
		}
	}
}