package com.cleartext.esm.models.valueObjects
{
	
	import flash.events.EventDispatcher;
	import flash.system.System;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	
	public class Chat extends EventDispatcher
	{
		public var contact:Contact;
		public var used:Boolean = true;
		public var messages:ArrayCollection;
		
		public function get isPerson():Boolean
		{
			return contact.isPerson;
		}
		
		public function get isGateway():Boolean
		{
			return contact.isGateway;
		}
		
		public function get isMicroBlogging():Boolean
		{
			return contact.isMicroBlogging;
		}
		
		public function get isGroup():Boolean
		{
			return contact is BuddyGroup;
		}
		
		public function get isChatRoom():Boolean
		{
			return contact is ChatRoom;
		}
		
		public var chatState:String;
		
		public function Chat(contact:Contact)
		{
			super();
			this.contact = contact;
			
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