package com.cleartext.ximpp.xmpp
{
	import com.cleartext.ximpp.model.XModel;
	import com.cleartext.ximpp.model.valueObjects.Buddy;
	import com.cleartext.ximpp.model.valueObjects.Status;
	import com.cleartext.ximpp.model.valueObjects.UserAccount;
	import com.hurlant.crypto.tls.TLSConfig;
	import com.hurlant.crypto.tls.TLSEngine;
	import com.hurlant.crypto.tls.TLSEvent;
	import com.hurlant.crypto.tls.TLSSocket;
	import com.seesmic.as3.xmpp.JID;
	import com.seesmic.as3.xmpp.StreamEvent;
	import com.seesmic.as3.xmpp.XMPP;
	import com.seesmic.as3.xmpp.XMPPEvent;
	
	public class XmppConnection
	{
		private var xmpp:XMPP = new XMPP();
		
		private function get xModel():XModel
		{
			return XModel.getInstance();
		}
		
		public function get connected():Boolean
		{
			return xmpp.state["connected"];
		}
		
		public function XmppConnection()
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
			xModel.log(event);
		}
		
		private function sessionHandler(event:XMPPEvent):void
		{
			xModel.log(event);
			xModel.serverSideStatus = xModel.localStatus;
			xmpp.getRoster();
			sendPresence();
		}
		
		private function secureHandler(event:XMPPEvent):void
		{
			xModel.log(event);
			
		}
		
		private function authSucceededHandler(event:XMPPEvent):void
		{
			xModel.log(event);
			
		}
		
		private function authFailedHandler(event:XMPPEvent):void
		{
			xModel.log(event);
		}
		
		private function presenceHandler(event:XMPPEvent):void
		{
			var stanza:Object = event.stanza;
			var from:JID = stanza["from"];
			xModel.log(event);
		}
		
		private function presenceUnavailableHandler(event:XMPPEvent):void
		{
			xModel.log(event);
			
		}
		
		private function presenceErrorHandler(event:XMPPEvent):void
		{
			xModel.log(event);
		}
		
		private function presenceSubscribeHandler(event:XMPPEvent):void
		{
			xModel.log(event);
		}
		
		private function rosterItemHandler(event:XMPPEvent):void
		{
			xModel.addBuddy(Buddy.createFromStanza(event.stanza));
		}
		
		public function connect():void
		{
			disconnect();
			
			xModel.serverSideStatus = Status.CONNECTING;

			var account:UserAccount = XModel.getInstance().userAccount;
			if(account &&
				account.jid &&
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
		 		xModel.log("Disconnecting from XMPP server");
		 		var presenceType:String = "<presence from='" + xmpp.fulljid.toString() + "' type='unavailable' status='Logged out' />";
				xmpp.send(presenceType);
		 		xmpp.disconnect();
		 		xModel.serverSideStatus = Status.OFFLINE;
		 	}
		}
		
		private function streamDisconnectedHandler(event:StreamEvent):void
		{
			xModel.log(event);
		}

		private function streamConnectFailedHandler(event:StreamEvent):void
		{
			xModel.log(event);
			xModel.serverSideStatus = Status.OFFLINE;
			if(!xModel.autoConnect)
				xModel.localStatus = Status.OFFLINE;
		}

		private function streamConnectedHandler(event:StreamEvent):void
		{
			xModel.log(event);	
		}
		
		public function sendPresence():void
		{
			var status:String = xModel.localStatus;
			var customStatus:String = xModel.userAccount.customStatus;

			// if we are connected and want to go offline, then disconnect
			if(connected && status == Status.OFFLINE)
			{
				disconnect();
			}
			
			// if we are already connected, then send the presence
			else if(connected)
			{
				xmpp.sendPresence(customStatus, Status.toShow(status), "5");
				xModel.serverSideStatus = status;
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