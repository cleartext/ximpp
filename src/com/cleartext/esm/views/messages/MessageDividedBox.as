package com.cleartext.esm.views.messages
{
	import com.cleartext.esm.models.ContactModel;
	import com.cleartext.esm.models.valueObjects.BuddyGroup;
	import com.cleartext.esm.models.valueObjects.Chat;
	import com.cleartext.esm.models.valueObjects.ChatRoom;
	import com.cleartext.esm.models.valueObjects.GlobalSettings;
	import com.cleartext.esm.models.valueObjects.Message;
	
	import mx.binding.utils.BindingUtils;
	import mx.containers.HDividedBox;
	import mx.controls.List;
	import mx.core.ClassFactory;

	public class MessageDividedBox extends HDividedBox
	{
		[Autowire(bean="settings", property="global")]
		[Bindable]
		public var global:GlobalSettings;
		
		[Autowire]
		public var buddies:ContactModel;
		
		private var participantList:List;
		private var messageList:MessageSproutList;
		
		public function get chat():Chat
		{
			return data as Chat;
		}
		
		public function get participantListWidth():Number
		{
			if(participantList)
				return width-getDividerAt(0).x;
			else
				return -1;
		}
		public function set participantListWidth(value:Number):void
		{
			if(participantList)
				callLater(function(v:Number):void { getDividerAt(0).x = width-v; }, [value]);
		}
		
		override public function set data(value:Object):void
		{
			super.data = value;
			
			if(chat)
			{
				messageList.data = chat;
					
				if(chat.contact is ChatRoom || chat.contact is BuddyGroup)
				{
					if(!participantList)
					{
						participantList = new List();
						participantList.itemRenderer = new ClassFactory(ChatRoomParticipantRenderer);
						participantList.selectable = false;
						participantList.setStyle("borderStyle", "none");
						participantList.percentHeight = 100;
						addChild(participantList);
					}
					participantList.dataProvider = chat.contact.participants;
				}
				else if(participantList)
				{
					removeChild(participantList);
					participantList = null;
				}
			}
		}

		public function MessageDividedBox()
		{
			super();
			percentWidth = 100;
			percentHeight = 100;

			messageList = new MessageSproutList();
			messageList.percentWidth = 100;
			messageList.percentHeight = 100;
			messageList.verticalScrollPolicy = "on";
		}
		
		public function set animate(value:Boolean):void
		{
			messageList.animate = value;
		}
		
		public function setSort(value:Boolean):void
		{
			if(chat)
			{
				for each(var message:Message in messageList.dataProvider)
				{
					if(message.sortBySentDate != value)
						message.sortBySentDate = value;
				}
				chat.messages.refresh();
			}
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			BindingUtils.bindSetter(setSort, global, "sortBySentDate");
			
			setSort(global.sortBySentDate);
			
			if(!contains(messageList))
			{
				addChildAt(messageList,0);
			}
		}
	}
}