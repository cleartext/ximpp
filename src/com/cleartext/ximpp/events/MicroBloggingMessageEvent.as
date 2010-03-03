package com.cleartext.ximpp.events
{
	import com.cleartext.ximpp.models.valueObjects.Message;
	
	import flash.events.Event;

	public class MicroBloggingMessageEvent extends Event
	{
		public static const MESSAGE_STATUS_CHANGED:String = "messageStatusChanged";
		
		public static const TWITTER_RETWEET:String = "twitterRetweet";
		public static const TWITTER_REPLY:String = "twitterReply";
		public static const TWITTER_DIRECT_MESSAGE:String = "twitterDirectMessage";
		public static const TWITTER_DELETE:String = "twitterDelete";
		
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