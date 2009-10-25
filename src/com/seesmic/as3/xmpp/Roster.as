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
	import flash.utils.Dictionary;
	
	public class Roster
	{
		public var items:Dictionary = new Dictionary();
		protected var conn:XMPP;
		
		public function Roster(conn:XMPP)
		{
			this.conn = conn;
		}
		
		public function updatePresence(jid:JID, type:String, status:String='', priority:String=null):void {
			if(!items.hasOwnProperty(barejid)) {
				newItem(jid);
			}
			var barejid:String = jid.getBareJID();
			var resource:String = jid.getResource();
			items[barejid]['presence'][resource] = new Dictionary();
			items[barejid]['presence'][resource]['type'] = type;
			items[barejid]['presence'][resource]['status'] = status;
			if(priority) {
				items[barejid]['presence'][resource]['priority'] = priority;
			}
		}
		
		public function updateItem(jid:JID, subscription:String='none', nick:String='', groups:Array=null):Dictionary {
			return newItem(jid, subscription, nick, groups);
		}
		
		private function newItem(jid:JID, subscription:String='not-in-list', nick:String='', groups:Array=null):Dictionary {
			var barejid:String = jid.getBareJID();
			if(!items.hasOwnProperty(barejid)) {
				items[barejid] = new Dictionary();
				items[barejid]['presence'] = new Dictionary();
				items[barejid]['jid'] = barejid;
			}
			items[barejid]['subscription'] = subscription;
			items[barejid]['nick'] = nick;
			items[barejid]['groups'] = groups;
			items[barejid]['name'] = nick;
			if(!items[barejid]['name']) items[barejid]['name'] = barejid;
			return items[barejid];
		}
		
		public function getHighestStatus(jid:String):Dictionary {
			if(!items.hasOwnProperty(jid)) return null;
			var toppriority:Number = -99999;
			var topresource:Dictionary;
			for(var resource:String in items[jid]['presence']) {
				if(Number(items[jid]['presence'][resource]['priority']) > toppriority) {
					toppriority = Number(items[jid]['presence'][resource]['priority']);
					topresource = items[jid]['presence'][resource]
				}
			}
			if(!topresource) {
				topresource = new Dictionary;
				topresource['type'] = 'unavailable';
				topresource['status'] = '';
				topresource['priority'] = '0';
			}
			return topresource;
		}
	}
}