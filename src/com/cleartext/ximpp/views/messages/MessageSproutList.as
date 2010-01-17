package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.views.common.StatusIcon;
	import com.universalsprout.flex.components.list.SproutList;
	
	import mx.core.ClassFactory;

	public class MessageSproutList extends SproutList
	{
		[Bindable]
		public var statusIcon:StatusIcon = new StatusIcon();
		
		override public function set data(value:Object):void
		{
			super.data = value;
			
			var chat:Chat = value as Chat;
			label = chat.buddy.nickName;
			dataProvider = chat.messages;
		}
		
		public function MessageSproutList()
		{
			super();
			itemRenderer = new ClassFactory(MessageRenderer);
			animate = false;
		}
	}
}