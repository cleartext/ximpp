package com.cleartext.esm.models.valueObjects
{
	public interface IMicroBloggingService
	{
		function parseMessage():Message;
		function get profileUrl(userId:String):String;
		function get sendLabel():String;
		
	}
}