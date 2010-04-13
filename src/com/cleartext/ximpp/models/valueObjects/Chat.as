package com.cleartext.ximpp.models.valueObjects
{
	
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	
	public class Chat extends EventDispatcher
	{
		public var buddy:Buddy;
		public var used:Boolean = true;
		public var messages:ArrayCollection;
		
		public function get microBlogging():Boolean
		{
			return buddy && buddy.microBlogging;
		}
		
		public var chatState:String;
		
		public function Chat(buddy:Buddy)
		{
			super();
			this.buddy = buddy;
			
			messages = new ArrayCollection();
			var sort:Sort = new Sort();
			sort.fields = [new SortField("time")];
			messages.sort = sort;
			messages.refresh()
		}
		
	}
}