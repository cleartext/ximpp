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
	public class JID
	{
		public var user:String = '';
		public var host:String = '';
		public var resource:String = '';
		
		public function JID(jid:String=null)
		{
			if(jid) fromString(jid);
		}
	
		public function fromString(jid:String):void {
			if(!jid) return;
			var tmp:Array;
			if(jid.search('@') > 0) {
				tmp = jid.split('@');
				user = tmp[0];
				host = tmp[1];
			} else {
				host = jid;
			}
			if(host.search('/') > 0) {
				tmp = host.split('/');
				resource = tmp[1];
				if(!resource) resource = ''
				host = tmp[0];
			}
		}
		
		public function getResource():String {
			return resource;
		}
		
		public function isSet():Boolean {
			if(this.user != '' || this.host != '') {
				return true;
			}
			return false;
		}
		
		public function getBareJID():String {
			var out:String;
			if(user) {
				out = user + '@' + host;
			} else {
				out = host; 
			}
			return out;
		}
		
		public function toString():String {
			var out:String = getBareJID();
			if(resource) out += '/' + resource;
			return out;
		}
	}
}