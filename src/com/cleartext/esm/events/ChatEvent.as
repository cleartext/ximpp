package com.cleartext.esm.events
{
	import com.cleartext.esm.models.valueObjects.Chat;
	import com.cleartext.esm.models.valueObjects.Contact;
	
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
		public var contact:Contact;
		
		public function ChatEvent(type:String, chat:Chat=null, index:int=-1, select:Boolean=false, contact:Contact=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.chat = chat;
			this.select = select;
			this.index = index;
			this.contact = contact;
		}
		
		override public function clone():Event
		{
			return new ChatEvent(type, chat, index, select, contact, bubbles, cancelable);	
		}
	}
}