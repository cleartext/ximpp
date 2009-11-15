package com.cleartext.ximpp.models.valueObjects
{
	import mx.collections.ArrayCollection;
	
	public class Chat extends EventDispatcher implements IXimppValueObject
	{
		public var messages():ArrayCollection();

		public function Chat()
		{
			super();
		}
		
		public function fill(obj:Object):void
		{
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			return null;
		}
		
		public function toString():String
		{
			return null;
		}
		
		public function toXML():XML
		{
			return null;
		}
		
	}
}