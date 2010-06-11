package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.events.BuddyModelEvent;
	import com.cleartext.ximpp.models.BuddyModel;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.GlobalSettings;
	import com.cleartext.ximpp.models.valueObjects.Group;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.views.buddies.BuddyRenderer;
	import com.universalsprout.flex.components.list.ISproutListData;
	import com.universalsprout.flex.components.list.SproutList;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.core.ClassFactory;
	import mx.core.IInvalidating;

	public class MessageSproutList extends SproutList
	{
		[Autowire(bean="settings", property="global")]
		[Bindable]
		public var global:GlobalSettings;
		
		[Autowire]
		public var buddies:BuddyModel;
		
		private var participantList:SproutList;
		
		public function get chat():Chat
		{
			return data as Chat;
		}
		
		private var _participants:ArrayCollection;
		public function get participants():ArrayCollection
		{
			return _participants;
		}
		public function set participants(value:ArrayCollection):void
		{
			if(_participants != value)
			{
				_participants = value;
				if(participantList)
					participantList.dataProvider = participants;
			}
		}
		
		override public function set data(value:Object):void
		{
			super.data = value;
			
			if(chat)
			{
				dataProvider = chat.messages;
				if(chat.buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					itemRenderer = new ClassFactory(AllMicroBloggingRenderer);
				else if(chat.isChatRoom)
					itemRenderer = new ClassFactory(MUCRenderer);
				else if(chat.isMicroBlogging || chat.isGroup)
					itemRenderer = new ClassFactory(MicroBloggingRenderer);
				else
					itemRenderer = new ClassFactory(ChatRenderer);

				participants = chat.buddy.participants;
				
				if(chat.buddy is Group)
					(chat.buddy as Group).addEventListener(BuddyModelEvent.REFRESH, refreshHandler);
			}
		}

		public function MessageSproutList()
		{
			super();
		}
		
		private function refreshHandler(event:BuddyModelEvent):void
		{
			participants = chat.buddy.participants;
		}
		
		public function setSort(value:Boolean):void
		{
			if(chat)
			{
				for each(var message:Message in dataProvider)
				{
					if(message.sortBySentDate != value)
					{
						message.sortBySentDate = value;
						
						var item:IInvalidating = itemRenderersByDataUid[message.uid] as IInvalidating;
						if(item)
							item.invalidateProperties();
					}
				}
				chat.messages.refresh();
			}
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			BindingUtils.bindSetter(setSort, global, "sortBySentDate");
			
			if(!participantList)
			{
				participantList = new SproutList();
				participantList.itemRenderer = new ClassFactory(BuddyRenderer);
				participantList.dataProvider = participants;
				addChild(participantList);
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(chat && !chat.isMicroBlogging && !chat.isGroup)
			{
				var previousJid:String;
				var previousMillis:Number = 0;
				
				for each(var data:ISproutListData in dataProvider)
				{
					var item:Object = itemRenderersByDataUid[data.uid];
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
			
			setChildIndex(participantList, numChildren-1);
			
			participantList.setActualSize(200, 400);
			participantList.move(unscaledWidth-240, 40);
		}
	}
}