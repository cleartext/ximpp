package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Status;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	import com.hurlant.crypto.tls.TLSConfig;
	import com.hurlant.crypto.tls.TLSEngine;
	import com.hurlant.crypto.tls.TLSEvent;
	import com.hurlant.crypto.tls.TLSSocket;
	import com.seesmic.as3.xmpp.JID;
	import com.seesmic.as3.xmpp.StreamEvent;
	import com.seesmic.as3.xmpp.XMPP;
	import com.seesmic.as3.xmpp.XMPPEvent;
	
	public class XMPPModel
	{
		private var xmpp:XMPP = new XMPP();
		
		[Autowire]
		[Bindable]
		public var appModel:ApplicationModel;
		
		private function get settings():SettingsModel
		{
			return appModel.settings;
		}
			
		private function get database():DatabaseModel
		{
			return appModel.database;
		}
				
		public function get connected():Boolean
		{
			return xmpp.state["connected"];
		}
		
		public function XMPPModel()
		{
			// set up event listeners
			xmpp.addEventListener(XMPPEvent.MESSAGE, messageHandler);
			xmpp.addEventListener(XMPPEvent.SESSION, sessionHandler);
			xmpp.addEventListener(XMPPEvent.SECURE, secureHandler);
			xmpp.addEventListener(XMPPEvent.AUTH_SUCCEEDED, authSucceededHandler);
			xmpp.addEventListener(XMPPEvent.AUTH_FAILED, authFailedHandler);
			xmpp.addEventListener(XMPPEvent.PRESENCE, presenceHandler);
//			xmpp.addEventListener(XMPPEvent.PRESENCE_UNAVAILABLE, presenceUnavailableHandler);
//			xmpp.addEventListener(XMPPEvent.PRESENCE_ERROR, presenceErrorHandler);
//			xmpp.addEventListener(XMPPEvent.PRESENCE_SUBSCRIBE, presenceSubscribeHandler);
			xmpp.addEventListener(XMPPEvent.ROSTER_ITEM, rosterItemHandler);
			xmpp.auto_reconnect = true;
			xmpp.reconnect_times
		}
		
		private function messageHandler(event:XMPPEvent):void
		{
			appModel.log(event);
		}
		
		private function sessionHandler(event:XMPPEvent):void
		{
			appModel.log(event);
			appModel.serverSideStatus = appModel.localStatus;
			xmpp.getRoster();
			sendPresence();
		}
		
		private function secureHandler(event:XMPPEvent):void
		{
			appModel.log(event);
			
		}
		
		private function authSucceededHandler(event:XMPPEvent):void
		{
			appModel.log(event);
			
		}
		
		private function authFailedHandler(event:XMPPEvent):void
		{
			appModel.log(event);
		}
		
		private function presenceHandler(event:XMPPEvent):void
		{
			var stanza:Object = event.stanza;
			
			var fromJid:JID = stanza["from"];
			var bareJid:String = fromJid.getBareJID();
			
			var buddy:Buddy;
			for each (var b:Buddy in appModel.buddies)
			{
				if(b.jid == bareJid)
				{
					buddy = b;
					break;
				}
			}
			
			if(!buddy)
				return;
				
			buddy.resource = fromJid.resource;
			buddy.status = Status.fromShow(stanza["type"]);
			appModel.log(stanza["type"] + " : " + buddy.status);
			buddy.customStatus = stanza["status"];
			
			database.saveBuddy(buddy);
			
			appModel.log(event);
		}
		
		private function presenceUnavailableHandler(event:XMPPEvent):void
		{
			appModel.log(event);
		}
		
		private function presenceErrorHandler(event:XMPPEvent):void
		{
			appModel.log(event);
		}
		
		private function presenceSubscribeHandler(event:XMPPEvent):void
		{
			appModel.log(event);
		}
		
		private function rosterItemHandler(event:XMPPEvent):void
		{
			appModel.addBuddy(Buddy.createFromStanza(event.stanza));
		}
		
		public function connect():void
		{
			disconnect();
			
			appModel.serverSideStatus = Status.CONNECTING;

			var account:UserAccount = settings.userAccount;
			if(account.jid &&
				account.password)
			{
				xmpp.setJID(account.jid);
				xmpp.setPassword(account.password);
				xmpp.setServer(account.server);
				
				xmpp.socket.addEventListener(StreamEvent.DISCONNECTED, streamDisconnectedHandler);
				xmpp.socket.addEventListener(StreamEvent.CONNECT_FAILED, streamConnectFailedHandler);
				xmpp.socket.addEventListener(StreamEvent.CONNECTED, streamConnectedHandler);
				
				// do the tls bit now
				xmpp.setupTLS(TLSEvent, TLSConfig, TLSEngine, TLSSocket, true, true, true);
				xmpp.connect();
			}
		}
		
		public function disconnect():void
		{
			if (connected)
			{
		 		appModel.log("Disconnecting from XMPP server");
		 		var presenceType:String = "<presence from='" + xmpp.fulljid.toString() + "' type='unavailable' status='Logged out' />";
				xmpp.send(presenceType);
		 		xmpp.disconnect();
		 		appModel.serverSideStatus = Status.OFFLINE;
		 		for each(var buddy:Buddy in appModel.buddies)
		 		{
		 			buddy.status = Status.OFFLINE;
		 			buddy.customStatus = "";
		 		}
		 	}
		}
		
		private function streamDisconnectedHandler(event:StreamEvent):void
		{
			appModel.log(event);
		}

		private function streamConnectFailedHandler(event:StreamEvent):void
		{
			appModel.log(event);
			appModel.serverSideStatus = Status.OFFLINE;
			if(!settings.autoConnect)
				appModel.localStatus = Status.OFFLINE;
		}

		private function streamConnectedHandler(event:StreamEvent):void
		{
			appModel.log(event);	
		}
		
		public function sendPresence():void
		{
			var status:String = appModel.localStatus;
			var customStatus:String = settings.userAccount.customStatus;

			// if we are connected and want to go offline, then disconnect
			if(connected && status == Status.OFFLINE)
			{
				disconnect();
			}
			
			// if we are already connected, then send the presence
			else if(connected)
			{
				xmpp.sendPresence(customStatus, Status.toShow(status), "5");
				appModel.serverSideStatus = status;
			}
			
			// if we want to connect, then try to connect, if we are successful, then
			// we will send the presence once the session is established
			else if(status != Status.OFFLINE)
			{
				connect();
			}	
		}

	}
}