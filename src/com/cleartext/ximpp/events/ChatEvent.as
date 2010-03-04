package com.cleartext.ximpp.events
{
	import com.cleartext.ximpp.models.valueObjects.Chat;
	
	import flash.events.Event;

	public class ChatEvent extends Event
	{
		public static const ADD_CHAT:String = "addChat";
		public static const REMOVE_CHAT:String = "removeChat";
		public static const SELECT_CHAT:String = "selectChat";
		public static const CHAT_CHANGED:String = "chatChanged";

		public var chat:Chat;
		
		public function ChatEvent(type:String, chat:Chat, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.chat = chat;
		}
		
		override public function clone():Event
		{
			return new ChatEvent(type, chat, bubbles, cancelable);	
		}
	}
}