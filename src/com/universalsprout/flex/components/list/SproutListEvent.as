package com.universalsprout.flex.components.list
{
	import flash.events.Event;

	public class SproutListEvent extends Event
	{
		public static const ITEM_DOUBLE_CLICKED:String = "itemDoubleClicked";
		
		public var data:ISproutListData;
		
		public function SproutListEvent(type:String, data:ISproutListData=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.data = data;
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new SproutListEvent(type, data, bubbles, cancelable);
		}
		
	}
}