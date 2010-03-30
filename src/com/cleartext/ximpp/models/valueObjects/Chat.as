package com.cleartext.ximpp.models.valueObjects
{
	
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	
	public class Chat extends EventDispatcher
	{
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