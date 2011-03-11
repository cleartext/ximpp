package com.cleartext.esm.models
{
	import com.cleartext.esm.events.ContactModelEvent;
	import com.cleartext.esm.events.HasAvatarEvent;
	import com.cleartext.esm.models.types.BuddySortTypes;
	import com.cleartext.esm.models.types.MicroBloggingTypes;
	import com.cleartext.esm.models.valueObjects.Buddy;
	import com.cleartext.esm.models.valueObjects.BuddyGroup;
	import com.cleartext.esm.models.valueObjects.ChatRoom;
	import com.cleartext.esm.models.valueObjects.Contact;
	import com.cleartext.esm.models.valueObjects.UserAccount;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;

	public class ContactModel extends EventDispatcher
	{
		[Autowire]
		public var appModel:ApplicationModel;
		
		[Autowire]
		public var database:DatabaseModel;
		
		[Autowire]
		public var settings:SettingsModel;

		public static const MICRO_BLOGGING_GROUP:String = "Social";
		public static const GATEWAY_GROUP:String = "Gateways";
		public static const ALL_BUDDIES_GROUP:String = "All Buddies";
		public static const OPEN_TABS:String = "Open Tabs";
		public static const UNASIGNED:String = "No Group";
		public static const CHAT_ROOMS:String = "Group Chats";
		
		private var buddiesByJid:Dictionary;

		private var _buddies:ArrayCollection;
		[Bindable(event="propertyChange")]
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
				dispatchEvent(new ContactModelEvent(ContactModelEvent.FILTER_CHANGED));
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
				dispatchEvent(new ContactModelEvent(ContactModelEvent.FILTER_CHANGED));
			}
		}
		
		public function set showOfflineBuddies(value:Boolean):void
		{
			settings.global.showOfflineBuddies = value;
			buddies.refresh();
			database.saveGlobalSettings();
			dispatchEvent(new ContactModelEvent(ContactModelEvent.FILTER_CHANGED));
		}
		
		public function ContactModel()
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
			sort.fields = [new SortField("nickname")];
			microBloggingBuddies.sort = sort;
			
			sort = new Sort();
			sort.fields = [new SortField("toString",true)];
			groups.sort = sort;
		}
		
		public function addBuddy(buddy:Contact, save:Boolean=true):void
		{
			if(buddy is UserAccount || buddiesByJid.hasOwnProperty(buddy.jid))
				return;

			buddies.addItem(buddy);
			buddiesByJid[buddy.jid] = buddy;
			buddy.addEventListener(HasAvatarEvent.CHANGE_SAVE, buddyChangeHandler, false, 0, true);

			if(save)
				buddy.dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
		}
		
		public function removeBuddy(contact:Contact):void
		{
			if(contact == Buddy.ALL_MICRO_BLOGGING_BUDDY)
				return;
			
			for(var i:int=buddies.source.length-1; i>=0; i--)
			{
				if(contact == buddies.source[i])
				{
					database.removeBuddy(contact);
					buddies.source.splice(i,1);

					contact.removeEventListener(HasAvatarEvent.CHANGE_SAVE, buddyChangeHandler);
					delete buddiesByJid[contact.jid];
					refresh();
					break;
				}
			}
		}

		public function getBuddyByJid(jid:String):Contact
		{
			return buddiesByJid[jid];
		}
		
		public function containsJid(jid:String):Boolean
		{
			return buddiesByJid.hasOwnProperty(jid);
		}

		private function buddyFilter(contact:Contact):Boolean
		{
			if(searchString == "" && 
				!settings.global.showOfflineBuddies && 
				contact.status.isOffline() && 
				!(contact is ChatRoom) && 
				!(contact is BuddyGroup))
				return false;
			
			var lower:String = searchString.toLowerCase();
			if(lower != "" && 
					contact.nickname.toLowerCase().search(lower) == -1 && 
					contact.jid.toLowerCase().search(lower) == -1 &&
					(contact.customStatus == null ||
						contact.customStatus.toLowerCase().search(lower) == -1))
				return false;
			
			if(groupName == OPEN_TABS)
				return contact.openTab;
			
			if(contact.isMicroBlogging)
				return groupName == MICRO_BLOGGING_GROUP;
			else if(contact is BuddyGroup || contact is ChatRoom)
				return groupName == CHAT_ROOMS;
			else if(contact.isGateway)
				return groupName == GATEWAY_GROUP;
			else if(groupName == ALL_BUDDIES_GROUP)
				return true;
			else if(contact is Buddy)
			{
				var b:Buddy = contact as Buddy;
				if(groupName == UNASIGNED && b.groups.length == 0)
					return true;
				else if(b.groups.indexOf(groupName) != -1)
					return true;
			}

			return false;
		}
		
		private function buddySort(c1:Contact, c2:Contact, fields:Object=null):int
		{
			if(groupName == MICRO_BLOGGING_GROUP)
			{
				if(c1 == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					return -1;
				else if(c2 == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					return 1;
			}

			switch(sortType)
			{
				case BuddySortTypes.ALPHABETICAL :
					return clamp(c1.nickname.localeCompare(c2.nickname));

				case BuddySortTypes.LAST_SEEN :
					return clamp(c2.lastSeen - c1.lastSeen);

				case BuddySortTypes.UNREAD_MESSAGES :
					var unreadCompare:int = clamp(c2.unreadMessages - c1.unreadMessages);
					if(unreadCompare != 0)
						return unreadCompare;
					var sCompare:int = clamp(c1.statusSortIndex - c2.statusSortIndex);
					if(sCompare != 0)
						return sCompare;
					return clamp(c1.nickname.localeCompare(c2.nickname));

				case BuddySortTypes.STATUS :
					var statusCompare:int = clamp(c1.statusSortIndex - c2.statusSortIndex);
					if(statusCompare != 0)
						return statusCompare;
					return clamp(c1.nickname.localeCompare(c2.nickname));
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
			
			for each(var contact:Contact in buddies.source)
			{
				if(contact == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					continue;
				
				if(contact.isMicroBlogging)
					microBloggingTemp.addItem(contact);

				else if(!(contact.isGateway))
				{
					var b:Buddy = contact as Buddy;
					if(b)
						for each(var group:String in b.groups)
							if(!groupsTemp.contains(group))
								groupsTemp.addItem(group);
				}
			}
			
			groups.list = groupsTemp.list;
			groups.refresh();

			microBloggingBuddies.list = microBloggingTemp.list;
			microBloggingBuddies.refresh();
			
			for each(var ib:Contact in buddies.source)
			{
				var g:BuddyGroup = ib as BuddyGroup;
				if(g)
					g.refresh(this);
			}
		}

		private function buddyChangeHandler(event:HasAvatarEvent):void
		{
			refresh();
			database.saveBuddy(event.target as Contact);
		}
		
		public function get realPeople():Array
		{
			var result:Array = new Array();
			for each(var contact:Contact in buddies.source)
				if(contact.isPerson)
					result.push(contact);
			
			return result.sortOn("nickname");
		}
		
		public function get nonMicroBlogging():Array
		{
			var result:Array = new Array();
			for each(var contact:Contact in buddies.source)
				if(!contact.isMicroBlogging)
					result.push(contact);
			
			return result.sortOn("nickname");
		}
		
		public function get gatewayNames():Array
		{
			var result:Array = ["default (xmpp)"];

			for each(var contact:Contact in buddies.source)
				if((contact.isGateway) && contact != Buddy.ALL_MICRO_BLOGGING_BUDDY)
					result.push(contact.jid);
			
			return result;
		}
		
		public function getBuddiesByGroup(groupName:String):Array
		{
			if(groupName == Buddy.ALL_MICRO_BLOGGING_JID)
				groupName = MicroBloggingTypes.MICRO_BLOGGING_GROUP;
			
			var result:Array = new Array();
			for each(var contact:Contact in buddies.source)
			{
				var b:Buddy = contact as Buddy;
				if(b && b.groups.indexOf(groupName) != -1)
					result.push(contact);
			}
			
			return result.sortOn("nickname");
		}
	}
}