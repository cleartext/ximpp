/*
This file is part of seesmic-as3-xmpp.
Copyright (c)2009 Seesmic, Inc

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

package com.seesmic.as3.xmpp
{

	import com.seesmic.as3.xmpp.xep.Plugin;
	
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.utils.Base64Encoder;
	
	public class XMPP extends XMLStream
	{
		private var jid:String;
		private var password:String;
		public var bound:Boolean = false;
		public var authed:Boolean = false;
		public var fulljid:JID;
		private var original_jid:JID;
		public var plugin:Dictionary = new Dictionary();
		
		private var reconnect_timer:Timer; 
		private var reconnect_index:uint = 0;
		
		public var reconnect_times:Array = [5,5,5,5,5,5,30,60];

		protected var host:String;
		private var stanzaId:uint = 0;
		public var auto_reconnect:Boolean = true;
		public var roster:Roster;
		
		
		private var ping_timer:Timer = new Timer(90000);
		private var pinged:Boolean = true;
		
		private var session_start_timeout:Timer = new Timer(30000, 1);
		
		
		public function XMPP(jid:String=null, password:String=null, server:String=null)
		{
			if(jid) setJID(jid);

			if(password) this.password = password;
			//trace('Connecting for ' + jid.toString() + ' on ' + server);
			if(server) setServer(server);
			rootStanzas['{jabber:client}iq'] =  IqStanza;
			rootStanzas['{jabber:client}message'] = MessageStanza;
			rootStanzas['{jabber:client}presence'] = PresenceStanza;				
			handlers = new Array();
			addHandler(new XPathHandler("{http://etherx.jabber.org/streams}features", StreamFeaturesHandler));
			addHandler(new XPathHandler('{jabber:client}message/{jabber:client}body', handleMessage));
			//astewart@cleartext.com
			addHandler(new XPathHandler('{jabber:client}message/{xmlns="http://jabber.org/protocol/chatstates"}', handleChatState));
			addHandler(new XPathHandler("{urn:ietf:params:xml:ns:xmpp-sasl}success", authSuccessHandler));
			addHandler(new XPathHandler("{urn:ietf:params:xml:ns:xmpp-sasl}failure", authFailureHandler));
			addHandler(new XPathHandler("{jabber:client}presence", handlePresence));
			addHandler(new XPathHandler("{jabber:client}iq/{jabber:iq:roster}query", rosterHandler));			
			ping_timer.addEventListener(TimerEvent.TIMER, pingServer);
			session_start_timeout.addEventListener(TimerEvent.TIMER, checkSessionTimeout);
		}
		
		public function setJID(jid:String):XMPP {
			if(!state['connected']) {
				var settingjid:Boolean = false;
				if(fulljid == null) {
					settingjid = true;	
				}
				fulljid = new JID(jid);
				if(settingjid) {
					original_jid = fulljid;
				}
				host = fulljid.host;
				if(!server) server = host;
			}
			return this;
		}
		
		public function setServer(server:String):XMPP {
			if(server) {
				this.server = server;
				if(!host) host = server;
			}
			stream_start = "<stream:stream to=\"" + host + "\" xmlns:stream='http://etherx.jabber.org/streams' xmlns='jabber:client' version='1.0'>";
			stream_end = "</stream:stream>";
			setup(this.server, 5222);
			socket.addEventListener(StreamEvent.DISCONNECTED, handleDisconnected);
			socket.addEventListener(StreamEvent.CONNECT_FAILED, handleConnectFailed);
			reset();
			return this;
		}
		
		override public function connect():void {
			session_start_timeout.start();
			super.connect();
		}
		
		public function setPassword(password:String):XMPP {
			this.password = password;
			return this;
		}
		
		private function reset():void {
			// reset the state
			stanzaId = 0;
			state['authed'] = false;
			state['session'] = false;
			state['bound'] = false;
			state['encrypted'] = false;
			state['session_feature'] = false;
			roster = new Roster(this);
			socket.reset();
		}
		
		private function checkSessionTimeout(e:TimerEvent):void {
			if(state['session'] == false) {
				trace("Session not established in 30 seconds, closing socket");
				state['connected'] = false;
				tryReconnect(true);
			}
		}
		
		public function addPlugin(pi:Plugin):void {
			this.plugin[pi.shortcut] = pi
			pi.setInstance(this);
			trace("Loading Plugin: " + pi.name);
			pi.init();
		}
		
		protected function handleDisconnected(e:StreamEvent):void {
			state['connected'] = false;
			tryReconnect(true);
			/**
			 * modified by astewart@cleartext.com
			 */
			dispatchEvent(e);
			/**/
		}
		
		protected function handleConnectFailed(e:StreamEvent):void {
			state['connected'] = false;
			tryReconnect(false);
			/**
			 * modified by astewart@cleartext.com
			 */
			dispatchEvent(e);
			/**/
		}
		
		private function tryReconnect(reset:Boolean=true):void {
			state['connected'] = false;
			ping_timer.stop();
			if(auto_reconnect && !state['disconnect_called']) {
				if (reset) reconnect_index = 0;
				trace("Waiting " + String(this.reconnect_times[this.reconnect_index]) + " seconds to reconnect.");
				reconnect_timer = new Timer(this.reconnect_times[this.reconnect_index] * 1000, 1);
				fulljid = original_jid;
				reconnect_timer.addEventListener(TimerEvent.TIMER, doReconnect);
				reconnect_timer.start();
				if (reconnect_index + 1 < reconnect_times.length) reconnect_index++; 	
			}
		}
		
		private function doReconnect(e:TimerEvent):void {
			if(!state['connected']) {
				reset();
				reconnect();
			} else {
				trace('Tried to reconnect, but was already connected.');
			}
		}

		public function newId():String {
			stanzaId += 1;
			//return "%X" % String(stanzaId);
			return String(stanzaId);
		}
		
		// astewart@cleartext.com
		private function handleChatState(msg:MessageStanza):void {
			dispatchEvent(new XMPPEvent(XMPPEvent.CHAT_STATE, false, false, msg));
		}
		
		private function handleMessage(msg:MessageStanza):void {
			if(msg.type == 'chat' || !msg.type || msg.type == 'normal') {
				dispatchEvent(new XMPPEvent(XMPPEvent.MESSAGE, false, false, msg));
			} else if (msg.type == 'groupchat') {
				dispatchEvent(new XMPPEvent(XMPPEvent.MESSAGE_MUC, false, false, msg));
			}
		}
		
		private function handlePresence(presence:PresenceStanza):void {
			dispatchEvent(new XMPPEvent(XMPPEvent.PRESENCE, false, false, presence));
			var cat:String = presence.getCategory();
			if(cat == 'available') {
				roster.updatePresence(presence.from, presence.type, presence.status, presence.priority);
				dispatchEvent(new XMPPEvent(XMPPEvent.PRESENCE_AVAILABLE, false, false, presence));
			} else if (cat == 'unavailable') {
				roster.updatePresence(presence.from, presence.type, presence.status, presence.priority);
				dispatchEvent(new XMPPEvent(XMPPEvent.PRESENCE_UNAVAILABLE, false, false, presence));
			} else if (cat == 'error') {
				roster.updatePresence(presence.from, presence.type, presence.status, presence.priority);
				dispatchEvent(new XMPPEvent(XMPPEvent.PRESENCE_ERROR, false, false, presence));
			} else if (cat == 'subscribe') {
				dispatchEvent(new XMPPEvent(XMPPEvent.PRESENCE_SUBSCRIBE, false, false, presence));
			}
		}
		
		private function StreamFeaturesHandler(xml:Stanza):void {
			trace('got stream features');
			var xmlobj:XML = xml.getXML();
			if(use_tls && !(state['authed']) && !(state['encrypted']) && XPathMatch(xmlobj, '{http://etherx.jabber.org/streams}features/{urn:ietf:params:xml:ns:xmpp-tls}starttls')) {
				addHandler(new XPathHandler("{urn:ietf:params:xml:ns:xmpp-tls}proceed", TLSProceedHandler, true));
				socket.send("<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls' />");
			} else if (fulljid && password && !state['authed'] && MaskMatch(xmlobj, "<features xmlns='http://etherx.jabber.org/streams'><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>PLAIN</mechanism></mechanisms></features>")) {
				var encodedauth:Base64Encoder = new Base64Encoder();
				encodedauth.encode("\x00" + fulljid.user + "\x00" + password);
				send("<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>" + encodedauth.toString() + "</auth>" );
			} else if ((!fulljid || !password) && !state['authed'] && MaskMatch(xmlobj, "<features xmlns='http://etherx.jabber.org/streams'><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>ANONYMOUS</mechanism></mechanisms></features>")) {
				send("<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='ANONYMOUS' />" );
			} else if (!state['authed']) {
				trace("No authentication mechanism supported.");
				disconnect();
			} else if (state['authed']) {
				if (!state['bound'] && XPathMatch(xmlobj, '{http://etherx.jabber.org/streams}features/{urn:ietf:params:xml:ns:xmpp-bind}bind')) {
					namespace xmpp_bind = "urn:ietf:params:xml:ns:xmpp-bind";
					var id:String = newId();
					var iq:XML = <iq type='set' id={id}><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></iq>;
					iq.@id = id;
					if(fulljid) {
						var resx:XML = <resource>{fulljid.resource}</resource>;
						iq.xmpp_bind::bind.appendChild(resx);
					}
					addHandler(new IdHandler(String(id), bindResponseHandler));
					if(XPathMatch(xmlobj, '{http://etherx.jabber.org/streams}features/{urn:ietf:params:xml:ns:xmpp-session}session')) {
						state['session_feature'] = true;
					}
					send(iq.toXMLString());
				}
			}
		}
		
		private function bindResponseHandler(xml:Stanza):void {
			namespace xmpp_bind = "urn:ietf:params:xml:ns:xmpp-bind";
			var xmlObj:XML = xml.getXML();
			trace('binding to', xmlObj.xmpp_bind::bind.xmpp_bind::jid.text());
			dispatchEvent(new XMPPEvent(XMPPEvent.BOUND, false, false, xml));
			fulljid = new JID(xmlObj.xmpp_bind::bind.xmpp_bind::jid.text());
			if(state['session_feature']) {
				var id:String = newId();
				addHandler(new IdHandler(String(id), sessionResponseHandler));
				var sessionrequest:String = "<iq type='set' id='" + id + "'><session xmlns='urn:ietf:params:xml:ns:xmpp-session' /></iq>";
				send(sessionrequest);
			}
		}
		
		private function sessionResponseHandler(xml:Stanza):void {	
			ping_timer.start();
			state['session'] = true;
			dispatchEvent(new XMPPEvent(XMPPEvent.SESSION));
		}
		
		private function pingServer(e:TimerEvent):void {
			if(!pinged) {
				ping_timer.stop()
				pinged = true; // reset it so that it doesn't error next time
				state['connected'] = false;
				tryReconnect(true);
				return;
			}
			pinged = false;
			var id:String = newId()
			var pingxml:XML = <iq to={host} id={id} type='get'><ping xmlns='urn:xmpp:ping'/></iq>;
			addHandler(new IdHandler(String(id), pingResponseHandler));
			send(pingxml.toXMLString());
		}
		
		private function pingResponseHandler(xml:Stanza):void {
			trace('got ping');
			pinged = true;
		}
		
		private function TLSProceedHandler(xml:Stanza):void {
			//socket.addEventListener(StreamEvent.TLS_READY, startTLSStream);
			startTLS(host);
			state['encrypted'] = true;
			send(stream_start);
			dispatchEvent(new XMPPEvent(XMPPEvent.SECURE));
		}
		
		
		private function authSuccessHandler(xml:Stanza):void {
			dispatchEvent(new XMPPEvent(XMPPEvent.AUTH_SUCCEEDED));
			state['authed'] = true;
			send(stream_start);
			socket.reset()
		}
		
		private function authFailureHandler(xml:Stanza):void {
			state['auth_failed'] = true;
			dispatchEvent(new XMPPEvent(XMPPEvent.AUTH_FAILED));
			disconnect();
		}
		
		public function sendMessage(tojid:String, msg:String, subject:String=null, type:String='chat', chatStatus:String=null):void {
			var nmsg:MessageStanza = new MessageStanza(this);
			nmsg.setTo(tojid);
			nmsg.setFrom(fulljid.toString());
			nmsg.setBody(msg);
			nmsg.setType(type);
			nmsg.setChatState(chatStatus);
			nmsg.send();
			//send("<message type='" + type + "' from='" + fulljid.toString() + "' to='" + tojid + "'><body>" + msg + "</body></message>");
		}
		
		/**
		 * modified by astewart@cleartext.com
		 * added PresenceStanza avatarHash property
		 */
		public function sendPresence(status:String=null,show:String=null,priority:String=null,tojid:String=null,avatarHash:String=null):void {
		/** old: public function sendPresence(status:String=null,show:String=null,priority:String=null,tojid:String=null):void {*/
			var npres:PresenceStanza = new PresenceStanza(this);
			if(tojid) {
				npres.setTo(tojid);
			}
			if(status) {
				npres.setStatus(status);
			}
			if(show) {
				npres.setType(show);
			}
			if(priority) {
				npres.setPriority(priority);
			}
			
			/**
			 * modified by astewart@cleartext.com
			 * added PresenceStanza avatarHash property
			 */
			if(avatarHash) {
				npres.setAvatarHash(avatarHash);
			}
			/**/

			npres.send();
		}
		
		public function getRoster():void {
			var iqs:IqStanza = new IqStanza(this);
			//iqs.setTo(host);
			iqs.setType('get');
			var queryx:XML = <query xmlns='jabber:iq:roster' />;
			iqs.setQuery(queryx);
			var id:String = iqs.setID();
			//addHandler(new IdHandler(id, rosterHandler));
			iqs.send();
		}
		
		public function rosterHandler(stanza:Stanza):void {
			namespace rosterns = "jabber:iq:roster";
			var xml:XML = stanza.getXML();
			
			if(xml.@type != 'error') {
				var groups:Array;
				var result:Dictionary;
				for each(var item:XML in xml.rosterns::query.rosterns::item) {
					groups = new Array();

					/**
					 * modified by astewart@cleartext.com
					 * previous groups parsing did not work without namespace
					 */
					for each(var group:XML in item.rosterns::group) {
						var gText:String = String(group.text());
						if(gText != null && gText != "")
							groups.push(gText);
					}

					/** old: for each(var group:XML in item.group) { */

					var jid:JID = new JID(item.@jid);
					result = roster.updateItem(jid, item.@subscription, item.@name, groups);
					dispatchEvent(new XMPPEvent(XMPPEvent.ROSTER_ITEM, false, false, result));
				}
			} else {
				dispatchEvent(new XMPPEvent(XMPPEvent.ROSTER_ERROR, false, false, stanza));
			}
		}
		
		public override function getInstance():Object {  // I need the real instance, so override this (gross, I'm not used to single inheritance/strict type)
			return this;
		}

		override public function disconnect():void {
			super.disconnect();
			ping_timer.stop();
		}

	}
}