package com.cleartext.ximpp.models.valueObjects
{
	import flash.events.IEventDispatcher;
	
	public interface IHasStatus extends IEventDispatcher
	{
//		function get jid():String;
//		function set jid(value:String):void;
//
//		function get nickname():String
//		function set nickname(value:String):void
//		
		function get status():Status;
		function setStatus(value:String):void
		
		function get statusSortIndex():int;
		
	}
}