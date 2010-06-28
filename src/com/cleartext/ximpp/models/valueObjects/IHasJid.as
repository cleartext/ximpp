package com.cleartext.ximpp.models.valueObjects
{
	public interface IHasJid
	{
		function get jid():String;
		function set jid(value:String):void
		
		function get nickname():String;
		function set nickname(value:String):void
	}
}