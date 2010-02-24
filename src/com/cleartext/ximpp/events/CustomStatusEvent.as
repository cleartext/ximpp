package com.cleartext.ximpp.events
{
	import flash.events.Event;

	public class CustomStatusEvent extends Event
	{
		public static const CUSTOM_STATUS_CHANGE:String = "customStatusChange";

		public var customStatus:String;
		
		public function CustomStatusEvent(type:String, customStautus:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.customStatus = customStautus;
		}
		
		override public function clone():Event
		{
			return new CustomStatusEvent(type, customStatus, bubbles, cancelable);
		}
		
	}
}