package com.universalsprout.flex.components.list
{
	import flash.events.EventDispatcher;
	
	import mx.utils.UIDUtil;
	
	[Event(name="propertyChange", type="mx.events")]

	public class SproutListDataBase extends EventDispatcher implements ISproutListData
	{
		private var _uid:String;
		public function get uid():String
		{
			if(!_uid)
				_uid = UIDUtil.createUID();
			return _uid;
		}
	}
}