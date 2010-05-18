package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.universalsprout.flex.components.list.ISproutListData;
	import com.universalsprout.flex.components.list.SproutList;
	
	import mx.core.ClassFactory;

	public class MessageSproutList extends SproutList
	{
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
						var thisMillis:Number = item.message.timestamp.time;
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