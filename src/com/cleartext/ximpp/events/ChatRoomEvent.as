package com.cleartext.ximpp.events
{
	import flash.events.Event;

	public class ChatRoomEvent extends Event
	{
		public static const PRESENCE:String = "presence";
		public static const MESSAGE:String = "message";
		public static const ERROR:String = "error";
		public static const IQ:String = "iq";
	
		public function ChatRoomEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new ChatRoomEvent(type, bubbles, cancelable);
		}
		
	}
}