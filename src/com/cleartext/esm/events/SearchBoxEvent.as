package com.cleartext.esm.events
{
	import flash.events.Event;

	public class SearchBoxEvent extends Event
	{
		public static const SEARCH:String = "search";
		
		public var searchString:String;
		
		public function SearchBoxEvent(searchString:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(SEARCH, bubbles, cancelable);
			this.searchString = searchString;
		}
		
		override public function clone():Event
		{
			return new SearchBoxEvent(searchString, bubbles, cancelable);
		}
		
	}
}