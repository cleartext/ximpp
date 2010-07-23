package com.cleartext.esm.models.valueObjects
{
	import flash.events.IEventDispatcher;
	
	public interface IHasStatus extends IEventDispatcher
	{
		function get status():Status;
		function setStatus(value:String):void
		
		function get statusSortIndex():int;
	}
}