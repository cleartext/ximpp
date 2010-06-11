package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.BuddyRequestEvent;
	import com.cleartext.ximpp.models.types.SubscriptionTypes;
	import com.cleartext.ximpp.models.valueObjects.BuddyRequest;
	import com.cleartext.ximpp.models.valueObjects.IBuddy;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	
	import org.swizframework.Swiz;
	
	public class BuddyRequestModel extends EventDispatcher
	{
		[Autowire]
		public var appModel:ApplicationModel;
		
		[Autowire]
		public var database:DatabaseModel;
		
		[Autowire]
		public var settings:SettingsModel;

		private var _requests:ArrayCollection;
		public function get requests():ArrayCollection
		{
			return _requests;
		}
		
		private var requestsByJid:Dictionary;
		
		public function BuddyRequestModel()
		{
			_requests = new ArrayCollection();
			requestsByJid = new Dictionary();

			var sort:Sort = new Sort();
			sort.fields = [new SortField("timestamp", false, true)];
			requests.sort = sort;
		}
		
		public function addRequest(request:BuddyRequest):void
		{
			if(!requestsByJid.hasOwnProperty(request.jid))
			{
				requests.addItem(request);
				requestsByJid[request.jid] = request;
				request.addEventListener(BuddyRequestEvent.BUDDY_REQUEST_CHANGED, requestChangedHandler, false, 0, true);
				requests.refresh();
				database.saveRequest(request);
				
				Swiz.dispatchEvent(new BuddyRequestEvent(BuddyRequestEvent.NEW_REQUEST));
			}
		}
		
		public function removeRequest(request:BuddyRequest):void
		{
			var i:int = requests.getItemIndex(request);
			if(i != -1)
				requests.removeItemAt(i);
			delete requestsByJid[request.jid];
			request.removeEventListener(BuddyRequestEvent.BUDDY_REQUEST_CHANGED, requestChangedHandler);
			database.removeRequest(request);
			Swiz.dispatchEvent(new BuddyRequestEvent(BuddyRequestEvent.REMOVE_REQUEST));
		}
		
		private function requestChangedHandler(event:BuddyRequestEvent):void
		{
			var request:BuddyRequest = event.target as BuddyRequest;
			requests.refresh();
			database.saveRequest(request);
		}
		
		public function setSubscription(jid:String, nickname:String, subscription:String):void
		{
			var request:BuddyRequest = requestsByJid[jid];
			
			if(!request)
				return;
			
			if(subscription == SubscriptionTypes.BOTH ||
				request.incomming && subscription == SubscriptionTypes.FROM ||
				!request.incomming && subscription == SubscriptionTypes.TO)
			{
				removeRequest(request);
			}
			else
			{
				request.nickname = nickname;
			}
		}
		
		public function sending(toJid:String):void
		{
			var request:BuddyRequest = requestsByJid[toJid];
			
			if(!request)
			{
				request = new BuddyRequest();
				request.jid = toJid;
				addRequest(request);
			}
			request.timestamp = new Date();
			request.incomming = false;
			var buddy:IBuddy = appModel.getBuddyByJid(toJid);
			if(buddy)
				request.nickname = buddy.nickname;
		}

		public function receiving(fromJid:String, nickname:String, message:String=null):void
		{
			var request:BuddyRequest = requestsByJid[fromJid];
			
			if(!request)
			{
				request = new BuddyRequest();
				request.jid = fromJid;
				addRequest(request);
			}
			request.timestamp = new Date();
			request.incomming = true;
			request.nickname = nickname;
			request.message = message;
		}
	}
}