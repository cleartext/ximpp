package com.cleartext.ximpp.models.valueObjects
{
	public interface IXimppValueObject
	{
		function fill(obj:Object):void;
		
		function toDatabaseValues(userId:int):Array;
		
		function toString():String;
		
		function toXML():XML;
	}
}