package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.universalsprout.flex.components.list.SproutList;
	
	import flash.events.Event;
	import flash.utils.setTimeout;
	
	import mx.core.ClassFactory;

	public class MessageSproutList extends SproutList
	{
		override public function set data(value:Object):void
		{
			super.data = value;
			dataProvider = (value as Chat).messages;
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		public function addedToStageHandler(event:Event):void
		{
			setTimeout(invalidateLater, 100);
		}
		
		public function MessageSproutList()
		{
			super();
			itemRenderer = new ClassFactory(MessageRenderer);
			animate = false;
		}
	}
}