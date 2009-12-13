package com.cleartext.ximpp.models.valueObjects
{
	public interface IXimppValueObject
	{
		function toDatabaseValues(userId:int):Array;
		
		function toString():String;
	}
}