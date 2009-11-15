package com.universalsprout.flex.components.list
{
	import flash.events.IEventDispatcher;
	
	public interface ISproutListData extends IEventDispatcher
	{
		function get uid():String;
	}
}