package com.cleartext.ximpp.events
{
	import flash.events.Event;

	public class StatusEvent extends Event
	{
		public static const STATUS_CHANGED:String = "statusChanged";
		
		public function StatusEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new StatusEvent(type, bubbles, cancelable);
		}
	}
}