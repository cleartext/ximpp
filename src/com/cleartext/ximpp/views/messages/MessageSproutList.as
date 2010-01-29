package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.universalsprout.flex.components.list.SproutList;
	
	import mx.core.ClassFactory;

	public class MessageSproutList extends SproutList
	{
		override public function set data(value:Object):void
		{
			super.data = value;
			dataProvider = (value as Chat).messages;
		}
		
		public function MessageSproutList()
		{
			super();
			setStyle("paddingTop", 200);
			itemRenderer = new ClassFactory(MessageRenderer);
			animate = false;
		}
	}
}