package com.cleartext.ximpp.models.valueObjects
{
	public interface IXimppValueObject
	{
		function fill(obj:Object):void;
		
		function toDatabaseValues(userId:int=-1):Array;
		
		function toString():String;
	}
}