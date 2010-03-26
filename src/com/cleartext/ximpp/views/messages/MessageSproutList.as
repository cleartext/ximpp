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
				else if(chat.microBlogging)
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
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if(chat && !chat.microBlogging)
			{
				var previousJid:String;
				for each(var data:ISproutListData in dataProvider)
				{
					var item:ChatRenderer = itemRenderersByDataUid[data.uid] as ChatRenderer;
					if(item)
					{
						var thisJid:String = item.message.sender;
						item.showTopRow = (thisJid != previousJid);
						previousJid = thisJid;
					}
				}
			}
		}
	}
}