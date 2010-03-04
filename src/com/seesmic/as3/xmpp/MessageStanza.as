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
	public class MessageStanza extends Stanza
	{
		public var from:JID = new JID();
		public var to:JID = new JID();
		public var type:String = 'chat';
		public var body:String;
		public var subject:String;
		namespace jc = 'jabber:client';
		default xml namespace = 'jabber:client';
		
		/**
		 * modified by astewart@cleartext.com
		 * html property added
		 */
		public var html:String;
		public var chatState:String = "";

		public static const states:Array = ["active", "composing", "paused", "inactive", "gone"];
		/**/
		
		public function MessageStanza(connection:Object, parent:Stanza=null)
		{
			super(connection, parent);
		}
		
		override public function fromXML(inxml:XML):void {
			super.fromXML(inxml);
			default xml namespace = "jabber:client";
			from.fromString(xml.@from);
			to.fromString(xml.@to);
			this.type = xml.@type;
			this.subject = xml.@subject;
			this.body = xml.body.text();

			/**
			 * modified by astewart@cleartext.com
			 * html property added
			 */
			this.html = xml.html.text();
			
			chatState = "";
			for each(var possibleState:String in states)
				if(xml.children().contains(new XML("<" + possibleState + " xmlns='http://jabber.org/protocol/chatstates'/>")))
					chatState = possibleState;
			
			/**/
		}
		
		public function setTo(nto:String):void {
			this.to.fromString(nto);
		}
		
		public function setFrom(nfrom:String):void {
			this.from.fromString(nfrom);
		}
		
		public function setBody(nbody:String):void {
			this.body = nbody;
		}
		
		/**
		 * modified by astewart@cleartext.com
		 * html property added
		 */
		public function setChatState(nstate:String):void {
			this.chatState = nstate;
		}
		
		public function setHtml(nhtml:String):void {
			this.html = nhtml;
		}
		/**/
		
		public function setSubject(nsubject:String):void {
			this.subject = nsubject;
		}
		
		public function setType(ntype:String): void {
			// TODO: verify type is valid;
			this.type = ntype;
		}
		
		override public function render():void {
			xml = <message />;
			//xml.setNamespace(jc);
			xml.@from = conn.fulljid.toString();
			xml.@to = to.toString();
			xml.@type = type;
			if(subject) {
				var subjectx:XML = new XML();
				subjectx = <subject>{this.subject}</subject>;
				xml.appendChild(subjectx);
			}
			
			if(body) {
				var bodyx:XML = new XML();
				bodyx = <body>{body}</body>;
				xml.appendChild(bodyx);
			}

			/**
			 * modified by astewart@cleartext.com
			 * html property added
			 */
			if(html) {
				var htmlx:XML = new XML();
				htmlx = <html>{html}</html>;
				xml.appendChild(htmlx);
			}
			
			if(chatState) {
				xml.appendChild(new XML("<" + chatState + " xmlns='http://jabber.org/protocol/chatstates'/>"));
			}
			else {
				xml.appendChild(new XML("<active xmlns='http://jabber.org/protocol/chatstates'/>"));
			}
			/**/
		}
		
		/**
		 * modified by astewart@cleartext.com
		 * html property added
		 */
		public function reply(newbody:String = null, newhtml:String = null):void {
		/** old: public function reply(newbody:String = null):void */
			// switch from and to, update body, re-render, send
			to = from;
			from = conn.fulljid;
			setBody(newbody);

			/**
			 * modified by astewart@cleartext.com
			 * html property added
			 */
			setHtml(newhtml);
			/**/

			send();
		}
	}
}