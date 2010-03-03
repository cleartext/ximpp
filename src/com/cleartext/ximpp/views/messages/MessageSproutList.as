package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.universalsprout.flex.components.list.ISproutListData;
	import com.universalsprout.flex.components.list.SproutList;
	
	import flash.events.Event;
	import flash.utils.setTimeout;
	
	import mx.core.ClassFactory;
	import mx.events.ResizeEvent;

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
				if(chat.microBlogging)
					itemRenderer = new ClassFactory(MicroBloggingRenderer);
				else
					itemRenderer = new ClassFactory(ChatRenderer);
			}
		}

		private function resizeLater(event:Event):void
		{
			setTimeout(invalidateDisplayList, 80);
		}
		
		public function MessageSproutList()
		{
			super();
			animate = false;

			addEventListener(ResizeEvent.RESIZE, resizeLater);
			addEventListener(Event.ADDED_TO_STAGE, resizeLater);
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(chat && !chat.microBlogging)
			{
				var previousJid:String;
				for each(var data:ISproutListData in dataProvider)
				{
					var item:ChatRenderer = itemRenderersByDataUid[data.uid] as ChatRenderer;
					var thisJid:String = item.message.sender;
					item.showTopRow = (thisJid != previousJid);
					previousJid = thisJid;
				}
			}
		}
	}
}