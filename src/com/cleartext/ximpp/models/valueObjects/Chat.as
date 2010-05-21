package com.cleartext.ximpp.models.valueObjects
{
	
	import flash.events.EventDispatcher;
	import flash.system.System;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	
	public class Chat extends EventDispatcher
	{
		public var buddy:Buddy;
		public var used:Boolean = true;
		public var messages:ArrayCollection;
		
		public function get isMicroBlogging():Boolean
		{
			return buddy && buddy.isMicroBlogging;
		}
		
		public function get isGroup():Boolean
		{
			return buddy && buddy.isGroup;
		}
		
		public function get isChatRoom():Boolean
		{
			return buddy && buddy.isChatRoom;
		}
		
		public var chatState:String;
		
		public function Chat(buddy:Buddy)
		{
			super();
			this.buddy = buddy;
			
			messages = new ArrayCollection();
			var sort:Sort = new Sort();
			sort.fields = [new SortField("sortDate", false, true)];
			messages.sort = sort;
		}
		
		public function addMessage(message:Message, limit:int):void
		{
			messages.addItemAt(message, 0);
			while(messages.length > limit)
				messages.removeItemAt(messages.length-1);
			messages.refresh();
			
			System.gc();
		}
	}
}