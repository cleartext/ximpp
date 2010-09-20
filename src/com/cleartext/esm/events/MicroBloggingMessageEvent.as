package com.cleartext.esm.events
{
	import com.cleartext.esm.models.valueObjects.Message;
	
	import flash.events.Event;

	public class MicroBloggingMessageEvent extends Event
	{
		public static const MESSAGE_STATUS_CHANGED:String = "messageStatusChanged";
		
		public static const RETWEET:String = "retweet";
		public static const REPLY:String = "reply";
		public static const DIRECT_MESSAGE:String = "directMessage";
		
		public var message:Message;
		
		public function MicroBloggingMessageEvent(type:String, message:Message, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.message = message;
		}
		
		override public function clone():Event
		{
			return new MicroBloggingMessageEvent(type, message, bubbles, cancelable);
		}
		
	}
}