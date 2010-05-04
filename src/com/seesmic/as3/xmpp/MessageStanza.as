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
	import mx.formatters.DateFormatter;
	
	public class MessageStanza extends Stanza
	{
		public var from:JID = new JID();
		public var to:JID = new JID();
		public var type:String = 'chat';
		public var body:String;
		public var subject:String;
		public var nick:String;
		
		namespace ni = 'http://jabber.org/protocol/nick';
		namespace jc = 'jabber:client';
		namespace htmlns = "http://jabber.org/protocol/xhtml-im";
		namespace w3ns = "http://www.w3.org/1999/xhtml";
		default xml namespace = 'jabber:client';
		
		/**
		 * modified by astewart@cleartext.com
		 * html property added
		 */
		public var html:String;
		public var chatState:String = "";
		public var customTags:Array;
		public var utcTimestamp:Date;

		public static const states:Array = ["active", "composing", "paused", "inactive", "gone"];
		/**/
		
		public function MessageStanza(connection:Object, parent:Stanza=null)
		{
			super(connection, parent);
		}
		
		override public function fromXML(inxml:XML, xmlstring:String):void {
			super.fromXML(inxml, xmlstring);
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
			 
			// we need to get the html string from the original xmlstring to
			// preserve whitespace
			var result:Array = new RegExp("<html\\b[^>]*?>([\\s\\S]*?)</html>", "ig").exec(xmlstring);
			if(result && result.length > 1)
			{
				this.html = result[1];
				trace(result[1]);
			}
			
			nick = inxml.ni::nick;
			
			chatState = "";
			for each(var possibleState:String in states)
				if(xml.children().contains(new XML("<" + possibleState + " xmlns='http://jabber.org/protocol/chatstates'/>")))
					chatState = possibleState;
			
			customTags = new Array();

			for each(var x:XML in xml.*::x)
			{
				if(x.@stamp != undefined)
					utcTimestamp = parseDate(x.@stamp);
				else
					customTags.push(x);
			}

			for each(var entry:XML in xml.*::entry)
			{
				customTags.push(entry);
			}

			if(!utcTimestamp)
				setTimestamp();
				
			/**/
		}
		
		/** start **/
		
		public function parseDate(str:String):Date {
			var year:Number;
			var month:Number;
			var date:Number;
			var hour:Number;
			var min:Number;
			var sec:Number;
			
			if(str.indexOf("-") == -1)
			{
				// YYYYMMDDTJJ:NN:SS
				year = Number(str.substr(0,4));
				month = Number(str.substr(4,2)) -1;
				date = Number(str.substr(6,2));
				hour = Number(str.substr(9,2));
				min = Number(str.substr(12,2));
				sec = Number(str.substr(15,2));
			}
			else
			{
				// YYYY-MM-DDTJJ:NN:SSZ
				year = Number(str.substr(0,4));
				month = Number(str.substr(5,2)) -1;
				date = Number(str.substr(8,2));
				hour = Number(str.substr(11,2));
				min = Number(str.substr(14,2));
				sec = Number(str.substr(17,2));
			}
			return new Date(year, month, date, hour, min, sec);
		}
		
		public function createDateStr(date:Date):String {
			return date.fullYear + "-" +
				pad(date.month+1) + "-" +
				pad(date.date) + "T" + 
				pad(date.hours) + ":" + 
				pad(date.minutes) + ":" + 
				pad(date.seconds) + "Z";
		}

		public function hasCustomTagWithNamespace(uri:String):Boolean
		{
			for each(var x:XML in customTags)
				for each(var ns:Namespace in x.namespaceDeclarations())
					if(ns.uri == uri)
						return true;

			return false;
		}
		
		/**/
		
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
		
		public function addCustomTag(x:XML):void {
			if(!customTags)
				customTags = new Array();
			customTags.push(x);
		}
		
		public function setTimestamp(date:Date=null):void {
			if(!date)
				date = new Date();
			utcTimestamp = new Date(date.fullYearUTC, date.monthUTC, date.dateUTC, date.hoursUTC, date.minutesUTC, date.secondsUTC, date.millisecondsUTC);
		}
		
		public function setUtcTimestamp(date:Date):void {
			utcTimestamp = date;
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
				htmlx = <html xmlns="http://jabber.org/protocol/xhtml-im">{html}</html>;
				xml.appendChild(htmlx);
			}
			
			if(chatState) {
				xml.appendChild(new XML("<" + chatState + " xmlns='http://jabber.org/protocol/chatstates'/>"));
			}
			else {
				xml.appendChild(<active xmlns='http://jabber.org/protocol/chatstates'/>);
			}
			
			if(body) {
				if(!utcTimestamp)
					setTimestamp();

				var delayx:XML = <x xmlns='urn:xmpp:delay'/>;
				delayx.@from = conn.fulljid.toString();
				delayx.@stamp = createDateStr(utcTimestamp);
				xml.appendChild(delayx);
			}
			
			for each( var x:XML in customTags)
				xml.appendChild(x);
			/**/
		}
		
		public function pad(num:Number, len:int=2):String
		{
			var result:String = num.toString();
			while(result.length < len)
				result = "0" + result;
			return result;
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