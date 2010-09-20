package com.universalsprout.flex.components.list
{
	import flash.events.EventDispatcher;
	
	import mx.utils.UIDUtil;
	
	[Event(name="propertyChange", type="mx.events")]

	public class SproutListDataBase implements ISproutListData
	{
		public function SproutListDataBase()
		{
			super();
		}
		
		private var _uid:String;
		public function get uid():String
		{
			if(!_uid)
				_uid = UIDUtil.createUID();
			return _uid;
		}
		
		public function dispose():void
		{
			// override me
		}
	}
}