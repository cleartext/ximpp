package com.cleartext.esm.events
{
	import flash.events.Event;

	public class ContactModelEvent extends Event
	{
		public static const FILTER_CHANGED:String = "filterChanged";
		public static const REFRESH:String = "refresh";
		
		public function ContactModelEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}

		override public function clone():Event
		{
			return new ContactModelEvent(type, bubbles, cancelable);
		}
	}
}