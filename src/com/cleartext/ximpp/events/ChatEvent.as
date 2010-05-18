package com.cleartext.ximpp.events
{
	import com.cleartext.ximpp.models.valueObjects.Chat;
	
	import flash.events.Event;

	public class ChatEvent extends Event
	{
		public static const ADD_CHAT:String = "addChat";
		public static const REMOVE_CHAT:String = "removeChat";
		public static const SELECT_CHAT:String = "selectChat";
		
		public var chat:Chat;
		public var select:Boolean = false;
		public var index:int;
		
		public function ChatEvent(type:String, chat:Chat=null, index:int=-1, select:Boolean=false, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.chat = chat;
			this.select = select;
			this.index = index;
		}
		
		override public function clone():Event
		{
			return new ChatEvent(type, chat, index, select, bubbles, cancelable);	
		}
	}
}