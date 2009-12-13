package com.cleartext.ximpp.models.valueObjects
{
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	
	public class Chat extends EventDispatcher implements IXimppValueObject
	{
		public var buddy:Buddy;
		public var messages:ArrayCollection = new ArrayCollection();

		public function Chat(buddy:Buddy)
		{
			super();
			this.buddy = buddy;
		}
		
		public function fillFromDB(obj:Object):void
		{
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			return null;
		}
		
		override public function toString():String
		{
			return null;
		}
		
		public function toXML():XML
		{
			return null;
		}
		
	}
}