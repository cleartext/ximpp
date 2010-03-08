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