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
	public class IqStanza extends Stanza
	{
		public var from:String;
		public var to:String;
		public var type:String;
		public var query:XML;
		public var id:String;
		
		public function IqStanza(connection:XMPP, parent:Stanza=null)
		{
			super(connection, parent);
		}
		
		override public function fromXML(inxml:XML):void {
			
			this.xml = inxml;
			this.from = xml.@from;
			if(conn.fulljid) this.to = conn.fulljid.toString();
			this.type = xml.@type;
			this.id = xml.@id;
			if(xml.query) {
				this.query = xml.query[0];
			}
		}
		
		public override function makeReply():Stanza {
			setTo(from);
			setFrom(conn.fulljid.toString());
			for each(var stanza:Stanza in p) {
				stanza.makeReply()
			}
			return this;
		}
		
		public function setup(to:String, type:String, from:String=null):void {
			this.to = to;
			this.type = type;
			if(from) {
				this.from = from;
			} else {
				this.from = conn.fulljid;
			}
			
		}
		
		public function setTo(to:String):void {
			this.to = to;
		}
		
		public function setFrom(from:String):void {
			this.from = from;
		}
		
		public function setType(type:String):void {
			this.type = type;
		}
		
		public function setID(id:String=null):String {
			if(!id) {
				this.id = conn.newId();
			}
			return this.id;
		}
		
		public function setQuery(queryx:XML):void {
			query = queryx;
		}
		
		public override function render():void {
			if(!id) {
				setID();
			}
			xml = <iq />;
			if(to) {
				xml.@to = to;
			}
			xml.@from = conn.fulljid.toString();
			xml.@type = type;
			xml.@id = id;
	 
			if(query) {
				xml.appendChild(query);
			}
			
		}
		
		override public function noHandler():void {
			//if we don't handle and IQ packet, it means we don't support the query.
			if(type == 'get' || type == 'set') {
				var iq:XML = <iq type='error' />;
				iq.@to = xml.@from;
				iq.@from = conn.fulljid.toString();
				iq.@id = xml.@id;
				var found:Boolean = false;
				var queryns:String;
				for each(var sub:XML in xml.children()) {
					if(sub.localName() == 'query') {
						found = true;
						queryns = sub.namespace(); 
						break;
					}
				}
				if(found) {
					var query:XML = <query />;
					query.@xmlns = queryns;
					iq.appendChild(query);
				}
				var error:XML = <error type='cancel'><service-unavailable xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error>;
				iq.appendChild(error);
				conn.send(iq.toXMLString());
			}
		}
	}
}