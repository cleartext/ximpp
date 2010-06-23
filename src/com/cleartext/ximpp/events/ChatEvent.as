package com.cleartext.ximpp.events
{
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.IBuddy;
	
	import flash.events.Event;

	public class ChatEvent extends Event
	{
		public static const ADD_CHAT:String = "addChat";
		public static const REMOVE_CHAT:String = "removeChat";
		public static const SELECT_CHAT:String = "selectChat";

		public static const OPEN_ME:String = "openMe";
		
		public var chat:Chat;
		public var select:Boolean = false;
		public var index:int;
		public var buddy:IBuddy;
		
		public function ChatEvent(type:String, chat:Chat=null, index:int=-1, select:Boolean=false, buddy:IBuddy=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.chat = chat;
			this.select = select;
			this.index = index;
			this.buddy = buddy;
		}
		
		override public function clone():Event
		{
			return new ChatEvent(type, chat, index, select, buddy, bubbles, cancelable);	
		}
	}
}