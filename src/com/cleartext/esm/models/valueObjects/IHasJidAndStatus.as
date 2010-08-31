package com.cleartext.esm.models.valueObjects
{
	import flash.events.IEventDispatcher;
	
	public interface IHasJidAndStatus extends IEventDispatcher
	{
		function get jid():String
		function set jid(value:String):void
		
		function get nickname():String
		function set nickname(value:String):void
		
		function get status():Status;
		function setStatus(value:String):void
		
		function get statusSortIndex():int;
	}
}