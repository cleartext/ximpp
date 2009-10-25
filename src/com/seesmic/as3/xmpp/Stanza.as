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
	
	public class Stanza
	{
		public var conn:Object;
		public var xml:XML;
		public var ns:String;
		public var tagName:String;
		public var parent:Stanza;
		public var p:Object = new Object;
		
		public function Stanza(connection:Object, parent:Stanza=null)
		{
			this.conn = connection;
			this.parent = parent;
		}
		
		public function fromXML(inxml:XML):void {
			this.xml = inxml;
			var tmp:Object;
			if(!parent) {
				for(var xpath:String in conn.stanzas) {
					if(conn.XPathMatch(inxml, xpath)) {
						tmp = new conn.stanzas[xpath](conn, this);
						tmp.fromXML(inxml);
						p[tmp.plugin_name] = tmp;
					}
				}
			}
			// override and populate internal values
			// process internal stanzas
		}
		
		public function getXML():XML {
			return this.xml;
		}
		
		public function hasPlugin(sub:String):Boolean {
			return p.hasOwnProperty(sub);
		}
		
		public function update():void {
			// re-create this.xml based on internal flags/objects
		}
		
		public function noHandler():void {
			// what do you do when this stanza isn't handled?
		}
		
		public function render():void {
			// resets this.xml
		}
		
		public function send():void {
			render();
			conn.send(xml.toXMLString());
		}
		
		public function makeReply():Stanza {
			return this;
		}
		
		public function handled():void {
		}
		
	}
}