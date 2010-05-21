package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.GlobalSettings;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.universalsprout.flex.components.list.ISproutListData;
	import com.universalsprout.flex.components.list.SproutList;
	
	import mx.binding.utils.BindingUtils;
	import mx.core.ClassFactory;
	import mx.core.IInvalidating;

	public class MessageSproutList extends SproutList
	{
		[Autowire(bean="settings", property="global")]
		[Bindable]
		public var global:GlobalSettings;
		
		public function get chat():Chat
		{
			return data as Chat;
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
			}
		}

		public function MessageSproutList()
		{
			super();
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
		}
	}
}