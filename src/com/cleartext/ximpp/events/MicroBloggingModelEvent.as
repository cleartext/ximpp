package com.cleartext.ximpp.events
{
	import flash.events.Event;

	public class MicroBloggingModelEvent extends Event
	{
		public static const CHANGED:String = "changed";
		
		public function MicroBloggingModelEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new MicroBloggingModelEvent(type, bubbles, cancelable);
		}
		
	}
}