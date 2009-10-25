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

package com.seesmic.as3.xmpp.xep.publish_subscribe
{
	import com.seesmic.as3.xmpp.IdHandler;
	import com.seesmic.as3.xmpp.MessageStanza;
	import com.seesmic.as3.xmpp.XPathHandler;
	import com.seesmic.as3.xmpp.xep.Plugin;
	
	
	public class PublishSubscribe extends Plugin
	{
		
		public function PublishSubscribe()
		{
			super();
			this.name = "Publish-Subscribe (XEP-0060)";
			this.shortcut = "pubsub";
		}
		
		public override function init():void {
			trace("Loaded Publish-Subscribe Plugin");
			xmpp.addHandler(new XPathHandler("{jabber:client}message/{http://jabber.org/protocol/pubsub#event}event/{http://jabber.org/protocol/pubsub#event}items/{http://jabber.org/protocol/pubsub#event}item", itemEventHandler));
			xmpp.addHandler(new XPathHandler("{jabber:client}message/{http://jabber.org/protocol/pubsub#event}event/{http://jabber.org/protocol/pubsub#event}items/{http://jabber.org/protocol/pubsub#event}retract", retractEventHandler));
		}
		
		private function itemEventHandler(message:MessageStanza):void {
			dispatchEvent(new PubSubEvent(PubSubEvent.ITEM, false, false, message));
			trace("Publish-Subscribe Item Event");
		}
		
		private function retractEventHandler(message:MessageStanza):void {
			dispatchEvent(new PubSubEvent(PubSubEvent.RETRACT, false, false, message));
			trace("Publish-Subscribe Retract Event");
		}

		public function getItems(jid:String, node:String, callback:Function):void {
			var id:String = this.xmpp.newId();
			var out:XML = <iq type='get' xmlns='jabber:client' to={jid} id={id}><pubsub xmlns='http://jabber.org/protocol/pubsub'><items node={node} /></pubsub></iq>;
			this.xmpp.addHandler(new IdHandler(id, callback));
			this.xmpp.send(out.toXMLString());
		}
		
	}
}