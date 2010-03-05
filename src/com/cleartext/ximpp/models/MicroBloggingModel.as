package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	
	public class MicroBloggingModel extends EventDispatcher
	{
		[Autowire]
		public var database:DatabaseModel;
		
		private var buddiesByJid:Dictionary;

		private var _buddies:ArrayCollection;
//		[Bindable (event="changed")]
		public function get buddies():ArrayCollection
		{
			return _buddies;
		}
		
		public function MicroBloggingModel()
		{
			super();
	
			buddiesByJid = new Dictionary();
			
			_buddies = new ArrayCollection();
			var sort:Sort = new Sort();
			sort.fields = [new SortField("nickName", true)];
			buddies.sort = sort;
			buddies.refresh();
		}

		public function addBuddy(buddy:Buddy):void
		{
			if(buddies.list.getItemIndex(buddy) == -1)
			{
				buddies.addItem(buddy);
				buddiesByJid[buddy.jid] = buddy;
				buddy.addEventListener(BuddyEvent.CHANGED, buddyChangeHandler);
				buddies.refresh();
			}
//			dispatchEvent(new MicroBloggingModelEvent(MicroBloggingModelEvent.CHANGED));
			database.saveBuddy(buddy);
		}
		
		public function removeBuddy(buddy:Buddy):void
		{
			var index:int = buddies.getItemIndex(buddy);
			if(index != -1)
			{
				database.removeBuddy(buddy.buddyId);
				buddy.removeEventListener(BuddyEvent.CHANGED, buddyChangeHandler);
				buddies.removeItemAt(index);
				delete buddiesByJid[buddy.jid];
				buddies.refresh();
//				dispatchEvent(new MicroBloggingModelEvent(MicroBloggingModelEvent.CHANGED));
			}
		}

		public function reset():void
		{
			buddies.removeAll();
			buddies.refresh();
			buddiesByJid = new Dictionary();
//			dispatchEvent(new MicroBloggingModelEvent(MicroBloggingModelEvent.CHANGED));
		}

		public function getBuddyByJid(jid:String):Buddy
		{
			return buddiesByJid[jid];
		}
		
		public function containsJid(jid:String):Boolean
		{
			for each(var buddy:Buddy in buddies)
				if(buddy.jid == jid)
					return true;

			return false;
		}

		public function refresh():void
		{
			buddies.refresh();
		}

		private function buddyChangeHandler(event:BuddyEvent):void
		{
			database.saveBuddy(event.target as Buddy);
			buddies.refresh();
//			dispatchEvent(new MicroBloggingModelEvent(MicroBloggingModelEvent.CHANGED));
		}

	}
}