package com.cleartext.ximpp.models.valueObjects
{
	import flash.events.EventDispatcher;
	
	public class Gateway extends EventDispatcher implements IXimppValueObject
	{
		public var type:String;
		public var status:String;
		public var username:String;
		public var password:String;
		
		public function Gateway()
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