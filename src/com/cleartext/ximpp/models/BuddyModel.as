package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.events.BuddyModelEvent;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.BuddySortTypes;
	import com.cleartext.ximpp.models.valueObjects.GlobalSettings;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;

	public class BuddyModel extends EventDispatcher
	{
		[Autowire]
		[Bindable]
		public var database:DatabaseModel;
		
		[Autowire]
		[Bindable]
		public var settings:SettingsModel;
		
		public static const GATEWAY_GROUP:String = "Gateways";
		public static const ALL_BUDDIES_GROUP:String = "All Buddies";
		public static const UNASIGNED:String = "No Group";
		
		private var buddiesByJid:Dictionary;

		private var _buddies:ArrayCollection;
		[Bindable (event="changed")]
		public function get buddies():ArrayCollection
		{
			return _buddies;
		}
		
		[Bindable (event="groupsChanged")]
		public function get groups():Array
		{
			var result:Array = [];
			for each(var buddy:Buddy in buddies.source)
			{
				if(!buddy.isGateway)
					for each(var group:String in buddy.groups)
						if(result.indexOf(group) == -1)
							result.push(group);
			}
			return result;
		}
		
		private var _groupName:String = ALL_BUDDIES_GROUP;
		[Bindable (event="filterChanged")]
		public function get groupName():String
		{
			return _groupName;
		}
		public function set groupName(value:String):void
		{
			if(_groupName != value)
			{
				_groupName = value;
				buddies.refresh();
				dispatchEvent(new BuddyModelEvent(BuddyModelEvent.FILTER_CHANGED));
			}
		}

		private var _searchString:String = "";
		public function get searchString():String
		{
			return _searchString;
		}
		public function set searchString(value:String):void
		{
			value = value.toLowerCase();
			if(_searchString != value)
			{
				_searchString = value;
				buddies.refresh();
			}
		}

		[Bindable (event="filterChanged")]
		public function get sortType():String
		{
			return settings.global.buddySortMethod;
		}
		public function set sortType(value:String):void
		{
			if(sortType != value)
			{
				settings.global.buddySortMethod = value;
				buddies.refresh();
				database.saveGlobalSettings();
				dispatchEvent(new BuddyModelEvent(BuddyModelEvent.FILTER_CHANGED));
			}
		}
			
		public function BuddyModel()
		{
			super();
			
			buddiesByJid = new Dictionary();
			
			_buddies = new ArrayCollection();
			buddies.filterFunction = buddyFilter;
			var sort:Sort = new Sort();
			sort.compareFunction = buddySort;
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
			}
			dispatchEvent(new BuddyModelEvent(BuddyModelEvent.GROUPS_CHANGED));
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
				dispatchEvent(new BuddyModelEvent(BuddyModelEvent.GROUPS_CHANGED));
			}
		}

		public function reset():void
		{
			buddies.removeAll();
			buddiesByJid = new Dictionary();
			dispatchEvent(new BuddyModelEvent(BuddyModelEvent.GROUPS_CHANGED));
		}

		public function getBuddyByJid(jid:String):Buddy
		{
			if(!jid || jid=="")
				return null;
				
			if(jid == settings.userAccount.jid)
				return settings.userAccount;
			
			return buddiesByJid[jid];
		}
		
		public function containsJid(jid:String):Boolean
		{
			for each(var buddy:Buddy in buddies)
				if(buddy.jid == jid)
					return true;

			return false;
		}

		private function buddyFilter(buddy:Buddy):Boolean
		{
			if(!settings.global.showOfflineBuddies && buddy.status.isOffline())
				return false;
			
			if(searchString != "" && 
					(buddy.nickName.toLowerCase().search(searchString) == -1 && 
					buddy.jid.toLowerCase().search(searchString) == -1))
				return false; 
			
			if(groupName == ALL_BUDDIES_GROUP && !buddy.isGateway)
				return true;
			else if(groupName == GATEWAY_GROUP && buddy.isGateway)
				return true;
			else if(groupName == UNASIGNED && buddy.groups.length == 0)
				return true;
			else if(buddy.groups.indexOf(groupName) != -1)
				return true;

			return false;
		}
		
		private function buddySort(buddy1:Buddy, buddy2:Buddy, fields:Object=null):int
		{
			switch(sortType)
			{
				case BuddySortTypes.ALPHABETICAL :
					return clamp(buddy1.nickName.localeCompare(buddy2.nickName));

				case BuddySortTypes.LAST_SEEN :
					var date1:Date = buddy1.lastSeen;
					var date2:Date = buddy2.lastSeen;
					
					if(!date1 && !date2)
						return 0;
					if(!date1)
						return 1;
					if(!date2)
						return -1;
					return clamp(date2.time - date1.time);

				case BuddySortTypes.STATUS :
					var statusCompare:int = clamp(buddy1.status.sortNumber() - buddy2.status.sortNumber());
					if(statusCompare != 0)
						return statusCompare;
					return clamp(buddy1.nickName.localeCompare(buddy2.nickName));
			}
			return 0;
		}
		
		private function clamp(value:Number):int
		{
			if(value == 0)
				return 0;
			return (value > 0) ? 1 : -1;
		}

		public function refresh():void
		{
			buddies.refresh();
		}

		private function buddyChangeHandler(event:BuddyEvent):void
		{
			database.saveBuddy(event.target as Buddy);
			dispatchEvent(new BuddyModelEvent(BuddyModelEvent.GROUPS_CHANGED));
		}
		
	}
}