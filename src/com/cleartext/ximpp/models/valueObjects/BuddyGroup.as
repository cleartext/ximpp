package com.cleartext.ximpp.models.valueObjects
{
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	
	public class BuddyGroup extends ArrayCollection
	{
		public var name:String;
		
		private var _buddiesByJid:Dictionary;
		public function get buddiesByJid():Dictionary
		{
			return _buddiesByJid;
		}
		
		public function BuddyGroup(name:String)
		{
			super();
			this.name = name;
			_buddiesByJid = new Dictionary();
		}
		
		override public function addItem(item:Object):void
		{
			throw new Error();
		}

		override public function addItemAt(item:Object, index:int):void
		{
			throw new Error();
		}
		
		override public function removeAll():void
		{
			super.removeAll();
			resetBuddiesByJid();
		}
		
		public function resetBuddiesByJid():void
		{
			_buddiesByJid = new Dictionary();
		}
		
		public function getBuddy(jid:String):Buddy
		{
			return _buddiesByJid[jid];
		}
		
		public function addBuddy(buddy:Buddy, position:Number=NaN):void
		{
			if(!contains(buddy))
			{
				position = (isNaN(position)) ? length : position;
				super.addItemAt(buddy, position);
				_buddiesByJid[buddy.jid] = buddy;
			}
		}
		
		public function removeBuddy(buddy:Buddy):void
		{
			var index:int = getItemIndex(buddy);
			if(index != -1)
			{
				removeItemAt(index);
				delete _buddiesByJid[buddy.jid];
			}
		}
		
		public function containsJid(jid:String):Boolean
		{
			for each(var buddy:Buddy in this)
			{
				if(buddy.jid == jid)
					return true;
			}
			return false;
		}
	}
}