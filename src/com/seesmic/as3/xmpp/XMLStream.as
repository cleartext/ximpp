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
	//import com.hurlant.crypto.tls.TLSSocket;
	
	import flash.errors.*;
	import flash.events.*;
	import flash.utils.Dictionary;
	
	public class XMLStream extends EventDispatcher
	{	
		private var xmlDoc:XML = new XML()
		public var handlers:Array = new Array();
		public var stream_start:String = "<stream>";
		public var stream_end:String = "</stream>";
		public var rootStanzas:Dictionary = new Dictionary();
		public var stanzas:Dictionary = new Dictionary();
		public var socket:StreamSocket;
		protected var tlssocket:Object;
		public var server:String;
		public var port:uint;
		public var stream_started:Boolean = false;
		public var state:Object = new Object();
		public var tlspointers:Object = new Object();
		public var use_tls:Boolean = false;
		
		public function XMLStream(server:String=null, port:uint=0)
		{
			tlspointers['socket'] = null;
			tlspointers['event'] = null;
			tlspointers['engine'] = null;
			tlspointers['config'] = null;
			
			state['disconnect_called'] = false;
			state['connected'] = false;
			if(server && port) setup(server, port);
		}
		
		public function setupTLS(event:Class, config:Class, engine:Class, socket:Class, ignoreCommonName:Boolean=true, ignoreSelfSigned:Boolean=true, ignoreInvalidCert:Boolean=false):void {
			tlspointers['socket'] = socket;
			tlspointers['event'] = event;
			tlspointers['engine'] = engine;
			tlspointers['config'] = config;
			this.socket.tlsConfig = tlspointers['config'];
			this.socket.tlsEngine = tlspointers['engine'];
			this.socket.tlsEvent = tlspointers['event'];
			this.socket.tlsSocket = tlspointers['socket'];
			this.socket.setupTLS(event,config,engine,socket,ignoreCommonName, ignoreSelfSigned, ignoreInvalidCert);
			use_tls = true;
		}
		
		public function setup(server:String, port:uint):void {
			this.server = server;
			this.port = port;
			socket = new StreamSocket(server, port, incomingHandler);
			socket.tlsConfig = tlspointers['config'];
			socket.tlsEngine = tlspointers['engine'];
			socket.tlsEvent = tlspointers['event'];
			socket.tlsSocket = tlspointers['socket'];
			socket.setupTLS(tlspointers['event'],tlspointers['config'], tlspointers['engine'], tlspointers['socket']);
			socket.addEventListener(StreamEvent.CONNECTED, connectHandler);
		}
		
		public function startTLS(host:String):void {
			socket.startTLS(host);
		}
		
		public function send(out:String):void {
			socket.send(out);
		}
		
		public function addStanzaPlugin(pointer:Class):void {
			stanzas[pointer.plugin_xpath] = pointer;
		}
		
		public function connect():void {
			trace('attempting connection');
			socket.connect();
			state['connected'] = true;
		}
		
		public function reconnect(): void {
			trace('attempting to reconnect');
			socket.reconnect();
		}
		
		public function registerStanza(tag:String, pointer:Class):void {
			this.stanzas[tag] = pointer;
		}

		public function addHandler(handler:Object):void {
			this.handlers.push(handler);
		}
		
		private function connectHandler(event:Event):void {
			//dispatchEvent(event);
			socket.send(stream_start);
		}
		
		private function incomingHandler(xmlstring:String):void {
			var currentStanza:Object;
			//xmlDoc.parseXML(stream_string + xmlstring + "</" + stream_tag + ">");
			xmlDoc = XML(xmlstring);
			var xml:XML = xmlDoc.children()[0];
			var match:String = "{" + xml.namespace() + "}" + xml.localName();
			if(rootStanzas.hasOwnProperty(match)) {
				currentStanza = new rootStanzas[match](getInstance());
			} else {
				currentStanza = new Stanza(getInstance());
			}
			currentStanza.fromXML(xml);
			var matched:Boolean = false;
			var idx:int = 0;
			for each(var handler:XMLHandler in handlers) {
				if(handler.match(xml)) {
					matched = true;
					handler.pointer(currentStanza);
					if(handler.use_once) { //if the handler is one time use
						handlers.splice(idx, 1); //delete the handler
					}
				}
				idx++;
			}
			if(!matched) { // if nothing matched, call the default behavior.
				currentStanza.noHandler();
			}
		}
		
		public function XPathMatch(xml:XML, path:String):Boolean {
			return new XPathHandler(path).match(xml);
		}
		
		public function MaskMatch(xml:XML, search:String):Boolean {
			return new MaskHandler(search).match(xml);
		}
		
		public function getInstance():Object {  // I need the real instance, so override this (gross, I'm not used to single inheritance/strict type)
			return this;
		}

		public function disconnect():void {
			state['disconnect_called'] = true;
			socket.socket.close();
			state['connected'] = false;
		}
	}
}