package com.cleartext.esm.events
{
	import flash.events.Event;

	public class SendButtonEvent extends Event
	{
		public static const SEND_CLICKED:String = "sendClicked";
		
		public function SendButtonEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new SendButtonEvent(type, bubbles, cancelable);
		}
	}
}