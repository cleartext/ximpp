package com.cleartext.ximpp.models.valueObjects
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;

	public class GlobalSettings extends EventDispatcher implements IXimppValueObject
	{
		public function GlobalSettings()
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