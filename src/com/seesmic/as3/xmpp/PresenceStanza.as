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
	public class PresenceStanza extends Stanza
	{
		public var from:JID = new JID();
		public var to:JID = new JID();
		public var type:String = 'available';
		public var status:String = '';
		public var priority:String = '0';
		public var category:String = 'available';
		namespace jc = 'jabber:client';
		default xml namespace = 'jabber:client';
		
		
		public function PresenceStanza(connection:Object, parent:Stanza=null)
		{
			super(connection, parent);
		}
		
		override public function fromXML(inxml:XML):void {
			super.fromXML(inxml);
			default xml namespace = "jabber:client";
			from.fromString(xml.@from);
			to.fromString(xml.@to);
			this.type = xml.@type;
			this.status = xml.status.text();
			this.priority = xml.priority.text();
			if(!this.type) {
				this.type = xml.show.text();
			}
			if(!this.type) {
				this.type = 'available';
			}
		}
		
		public function getCategory():String {
			var available:Array = new Array('available', 'away', 'ffc', 'dnd', 'na');
			var subscribe:Array = new Array('subscribe', 'subscribed', 'unsubscribe');
			if(type == 'unavailable') {
				return 'unavailable';
			} else if (available.indexOf(type) != -1) {
				return 'available';
			} else if (subscribe.indexOf(type) != -1) {
				return 'subscribe';
			} else if (type == 'error') {
				return 'error';
			}
			return 'unknown';
		}
		
		public function setTo(nto:String):void {
			this.to.fromString(nto);
		}
		
		public function setFrom(nfrom:String):void {
			this.from.fromString(nfrom);
		}
		
		public function setStatus(nstatus:String):void {
			this.status = nstatus;
		}
		
		public function setPriority(npriority:String):void {
			this.priority = npriority;
		}
		
		public function setType(ntype:String): void {
			// TODO: verify type is valid;
			this.type = ntype;
		}
		
		override public function render():void {
			xml = <presence />;
			//xml.setNamespace(jc);
			//xml.@from = conn.fulljid.toString();
			if(this.to && this.to.isSet()) {
				xml.@to = to.toString();
			}
			if(this.type == 'unavailable') {
				xml.@type = 'unavailable';
			} else if (this.type && this.type != 'available') {
				var showx:XML = <show>{type}</show>;
				xml.appendChild(showx);
			}
			if(this.priority != '0') {
				var priorityx:XML = <priority>{priority}</priority>;
				xml.appendChild(priorityx);
			}
			if(this.status) {
				var statusx:XML = <status>{status}</status>;
				xml.appendChild(statusx);
			}
		}
				
	}
}