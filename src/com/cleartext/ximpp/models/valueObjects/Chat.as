package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.ChatEvent;
	import com.cleartext.ximpp.models.XMPPModel;
	
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	
	public class Chat extends EventDispatcher
	{
		[Autowire]
		public var xmppModel:XMPPModel;
		
		private var _unreadMessageCount:int = 0;
		[Bindable(event="chatChanged")]
		public function get unreadMessageCount():int
		{
			return _unreadMessageCount;
		}
		public function set unreadMessageCount(value:int):void
		{
			if(_unreadMessageCount != value)
			{
				_unreadMessageCount = value;
				dispatchEvent(new ChatEvent(ChatEvent.CHAT_CHANGED, this));
			}
		}
		
		public var buddy:Buddy;
		public var used:Boolean = true;
		public var messages:ArrayCollection = new ArrayCollection();
		
		public function get microBlogging():Boolean
		{
			return buddy && buddy.microBlogging;
		}
		
		public var chatState:String;
		
		public function Chat(buddy:Buddy)
		{
			super();
			this.buddy = buddy;
		}
		
	}
}