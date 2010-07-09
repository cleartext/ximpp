package com.cleartext.esm.views.messages
{
	import com.cleartext.esm.models.BuddyModel;
	import com.cleartext.esm.models.valueObjects.Buddy;
	import com.cleartext.esm.models.valueObjects.Chat;
	import com.cleartext.esm.models.valueObjects.ChatRoom;
	import com.cleartext.esm.models.valueObjects.GlobalSettings;
	import com.cleartext.esm.models.valueObjects.BuddyGroup;
	import com.cleartext.esm.models.valueObjects.Message;
	import com.universalsprout.flex.components.list.ISproutListData;
	import com.universalsprout.flex.components.list.SproutList;
	
	import mx.binding.utils.BindingUtils;
	import mx.containers.HDividedBox;
	import mx.controls.List;
	import mx.core.ClassFactory;

	public class MessageSproutList extends HDividedBox
	{
		[Autowire(bean="settings", property="global")]
		[Bindable]
		public var global:GlobalSettings;
		
		[Autowire]
		public var buddies:BuddyModel;
		
		private var participantList:List;
		private var messageList:SproutList;
		
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
				messageList.dataProvider = chat.messages;
				if(chat.buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					messageList.itemRenderer = new ClassFactory(AllMicroBloggingRenderer);
				else if(chat.isChatRoom)
					messageList.itemRenderer = new ClassFactory(MUCRenderer);
				else if(chat.isMicroBlogging || chat.isGroup)
					messageList.itemRenderer = new ClassFactory(MicroBloggingRenderer);
				else
					messageList.itemRenderer = new ClassFactory(ChatRenderer);
					
				if(chat.buddy is ChatRoom || chat.buddy is BuddyGroup)
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
					participantList.dataProvider = chat.buddy.participants;
				}
				else if(participantList)
				{
					removeChild(participantList);
					participantList = null;
				}
			}
		}

		public function MessageSproutList()
		{
			super();
			percentWidth = 100;
			percentHeight = 100;

			messageList = new SproutList();
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
			
			if(!contains(messageList))
			{
				addChildAt(messageList,0);
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(chat && !chat.isMicroBlogging && !chat.isGroup)
			{
				var previousJid:String;
				var previousMillis:Number = 0;
				
				for each(var data:ISproutListData in messageList.dataProvider)
				{
					var item:Object = messageList.itemRenderersByDataUid[data.uid];
					if(item && item.hasOwnProperty("showTopRow") && item.hasOwnProperty("message"))
					{
						var thisJid:String = chat.isChatRoom ? item.message.groupChatSender : item.message.sender;
						var thisMillis:Number = item.message.sortDate.time;
						item.showTopRow = (thisJid != previousJid || previousMillis-thisMillis > 1800000);
						previousJid = thisJid;
						previousMillis = thisMillis;
					}
				}
			}

			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
	}
}