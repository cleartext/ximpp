package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.events.BuddyModelEvent;
	import com.cleartext.ximpp.models.types.BuddySortTypes;
	import com.cleartext.ximpp.models.types.MicroBloggingTypes;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;

	public class BuddyModel extends EventDispatcher
	{
		[Autowire]
		public var database:DatabaseModel;
		
		[Autowire]
		public var settings:SettingsModel;

		public static const MICRO_BLOGGING_GROUP:String = "Social";
		public static const GATEWAY_GROUP:String = "Gateways";
		public static const ALL_BUDDIES_GROUP:String = "All Buddies";
		public static const OPEN_TABS:String = "Open Tabs";
		public static const UNASIGNED:String = "No Group";
		
		private var buddiesByJid:Dictionary;

		private var _buddies:ArrayCollection;
		public function get buddies():ArrayCollection
		{
			return _buddies;
		}
		
		[Bindable]
		public var microBloggingBuddies:ArrayCollection;
		
		[Bindable]
		public var groups:ArrayCollection;
		
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

			_buddies = new ArrayCollection();
			buddiesByJid = new Dictionary();

			groups = new ArrayCollection();
			microBloggingBuddies = new ArrayCollection();

			buddies.filterFunction = buddyFilter;
			var sort:Sort = new Sort();
			sort.compareFunction = buddySort;
			buddies.sort = sort;
			
			sort = new Sort();
			sort.fields = [new SortField("nickName")];
			microBloggingBuddies.sort = sort;
			
			sort = new Sort();
			sort.fields = [new SortField("toString",true)];
			groups.sort = sort;
		}
		
		public function addBuddy(buddy:Buddy):void
		{
			if(buddy is UserAccount || buddies.list.getItemIndex(buddy) != -1)
				return;

			buddies.addItem(buddy);
			buddiesByJid[buddy.jid] = buddy;
			buddy.addEventListener(BuddyEvent.CHANGED, buddyChangeHandler, false, 0, true);
			buddy.dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
		}
		
		public function removeBuddy(buddy:Buddy):void
		{
			if(buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
				return;
			
			var index:int = buddies.list.getItemIndex(buddy);
			if(index != -1)
			{
				database.removeBuddy(buddy.buddyId);
				buddy.removeEventListener(BuddyEvent.CHANGED, buddyChangeHandler);
				buddies.list.removeItemAt(index);
				delete buddiesByJid[buddy.jid];
			}
			refresh();
		}

		public function getBuddyByJid(jid:String):Buddy
		{
			return buddiesByJid[jid];
		}
		
		public function containsJid(jid:String):Boolean
		{
			return buddiesByJid.hasOwnProperty(jid);
		}

		private function buddyFilter(buddy:Buddy):Boolean
		{
			if(!settings.global.showOfflineBuddies && buddy.status.isOffline())
				return false;
			
			if(searchString != "" && 
					(buddy.nickName.toLowerCase().search(searchString.toLowerCase()) == -1 && 
					buddy.jid.toLowerCase().search(searchString.toLowerCase()) == -1))
				return false; 
			
			if(groupName == OPEN_TABS)
				return buddy.openTab;
			if(buddy.isMicroBlogging)
				return groupName == MICRO_BLOGGING_GROUP;
			else if(buddy.isGateway)
				return groupName == GATEWAY_GROUP;
			else if(groupName == ALL_BUDDIES_GROUP)
				return true;
			else if(groupName == UNASIGNED && buddy.groups.length == 0)
				return true;
			else if(buddy.groups.indexOf(groupName) != -1)
				return true;

			return false;
		}
		
		private function buddySort(buddy1:Buddy, buddy2:Buddy, fields:Object=null):int
		{
			if(groupName == MICRO_BLOGGING_GROUP)
			{
				if(buddy1 == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					return -1;
				else if(buddy2 == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					return 1;
			}

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

				case BuddySortTypes.UNREAD_MESSAGES :
					var unreadCompare:int = clamp(buddy2.unreadMessages - buddy1.unreadMessages);
					if(unreadCompare != 0)
						return unreadCompare;
					var sCompare:int = clamp(buddy1.status.sortNumber() - buddy2.status.sortNumber());
					if(sCompare != 0)
						return sCompare;
					return clamp(buddy1.nickName.localeCompare(buddy2.nickName));

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
			
			var groupsTemp:ArrayCollection = new ArrayCollection();
			var microBloggingTemp:ArrayCollection = new ArrayCollection();
			
			for each(var buddy:Buddy in buddies.source)
			{
				if(buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					continue;
				
				if(buddy.isMicroBlogging)
					microBloggingTemp.addItem(buddy);

				else if(!buddy.isGateway)
					for each(var group:String in buddy.groups)
						if(!groupsTemp.contains(group))
							groupsTemp.addItem(group);
			}
			
			groups.list = groupsTemp.list;
			groups.refresh();

			microBloggingBuddies.list = microBloggingTemp.list;
			microBloggingBuddies.refresh();
		}

		private function buddyChangeHandler(event:BuddyEvent):void
		{
			refresh();
			database.saveBuddy(event.target as Buddy);
		}
		
		public function get realPeople():Array
		{
			var result:Array = new Array();
			for each(var buddy:Buddy in buddies.source)
				if(!buddy.isGateway && !buddy.isMicroBlogging)
					result.push(buddy);
			
			return result.sortOn("nickName");
		}
		
		public function get nonMicroBlogging():Array
		{
			var result:Array = new Array();
			for each(var buddy:Buddy in buddies.source)
				if(!buddy.isMicroBlogging)
					result.push(buddy);
			
			return result.sortOn("nickName");
		}
		
		public function get gatewayNames():Array
		{
			var result:Array = ["none"];

			for each(var buddy:Buddy in buddies.source)
				if(buddy.isGateway)
					result.push(buddy.jid);
			
			return result.sortOn("nickName");
		}
		
		public function getBuddiesByGroup(groupName:String):Array
		{
			if(groupName == Buddy.ALL_MICRO_BLOGGING_JID)
				groupName = MicroBloggingTypes.MICRO_BLOGGING_GROUP;
			
			var result:Array = new Array();
			for each(var buddy:Buddy in buddies.source)
				if(buddy.groups.indexOf(groupName) != -1)
					result.push(buddy);
			
			return result.sortOn("nickName");
		}
	}
}