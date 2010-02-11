package com.cleartext.ximpp.events
{
	import flash.events.Event;

	public class ApplicationEvent extends Event
	{
		public static const APPLICATION_COMPLETE:String = "appComplete";
		
		public function ApplicationEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new ApplicationEvent(type, bubbles, cancelable);
		}
	}
}