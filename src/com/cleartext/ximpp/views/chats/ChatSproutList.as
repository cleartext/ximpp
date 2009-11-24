package com.cleartext.ximpp.views.chats
{
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.views.common.StatusIcon;
	import com.cleartext.ximpp.views.timeline.MessageRenderer;
	import com.universalsprout.flex.components.list.SproutList;
	
	import mx.core.ClassFactory;

	public class ChatSproutList extends SproutList
	{
		public var used:Boolean = false;
		
		[Bindable]
		public var statusIcon:StatusIcon = new StatusIcon();
		
		override public function set data(value:Object):void
		{
			super.data = value;
			
			var chat:Chat = value as Chat;
			label = chat.buddy.nickName;
			dataProvider = chat.messages;
		}
		
		public function ChatSproutList()
		{
			super();
			itemRenderer = new ClassFactory(MessageRenderer);
			animate = false;
			bottomUp = true;
		}
		
	}
}