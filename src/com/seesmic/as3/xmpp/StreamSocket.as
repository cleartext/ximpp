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
	//import com.hurlant.crypto.tls.*;
	
	import flash.events.*;
	import flash.net.Socket;
	import flash.utils.Timer;

	public class StreamSocket extends EventDispatcher
	{
		protected var callback:Function;
		protected var _ignoreInvalidCert:Boolean = false;
		protected var _ignoreCommonName:Boolean = true;
		protected var _ignoreSelfSigned:Boolean = true;
		public var buffer:String;
		private var getXML:RegExp;
		private var getTag:RegExp = /(?<=(\<))[a-zA-Z:]+/i;
		public var stream_started:Boolean = false;
		private var stream_string:String;
		private var stream_tag:String;
		//public var tlsclient:Object;
		public var socket:Object = null; // was :*
		private var keep_alive_timer:Timer;
		//public var tlssocket:Object;
		public var tlssocket:Object;
		public var encrypted:Boolean = false;
		public var state:Object = new Object();
		public var host:String;
		public var port:uint;
		
		public var tlsEvent:Object;
		public var tlsSocket:Object;
		public var tlsConfig:Object;
		public var tlsEngine:Object;
		
		
		public function StreamSocket(host:String=null, port:int=0, callback:Function=null)
		{
			state['connected'] = false;
			this.callback = callback;
			this.socket = new Socket();
			this.host = host;
			this.port = port;
			configureListeners();
			//this.socket.connect(host, port);
		}
		
		public function connect():void {
			state['connected'] = false;
			socket.connect(host, port);
			trace('setting up timer');
			keep_alive_timer = new Timer(120000);
			keep_alive_timer.addEventListener(TimerEvent.TIMER, keepAlive);
			keep_alive_timer.start();
		}
		
		public function keepAlive(e:TimerEvent):void {
			trace('sending keepalive');
			send(' ');
		}
		
		public function reconnect():void {
			if(tlssocket) {
				//tlssocket.cleanupEventListeners();
				tlssocket = null;
			}
			socket = new Socket();
			configureListeners();
			socket.connect(host, port);
		}
		
		public function setupTLS(event:Class, config:Class, engine:Class, socket:Class, ignoreCommonName:Boolean=true, ignoreSelfSigned:Boolean=true, ignoreInvalidCert:Boolean=false):void {
			this.tlsConfig = config;
			this.tlsEngine = engine;
			this.tlsEvent = event;
			this.tlsSocket = socket;
			this._ignoreInvalidCert = ignoreInvalidCert;
			this._ignoreCommonName = ignoreCommonName;
			this._ignoreSelfSigned = ignoreSelfSigned;
			trace('setup called');
		}
		
		public function startTLS(host:String):void {
			try {
				trace(tlsConfig);
				trace(tlsEngine);
				var clientConfig:Object = new this.tlsConfig(this.tlsEngine.CLIENT);
				clientConfig.ignoreCommonNameMismatch = this._ignoreCommonName;
				clientConfig.trustAllCertificates = this._ignoreInvalidCert;
				clientConfig.trustSelfSignedCertificates = this._ignoreSelfSigned;
				encrypted = true;
				tlssocket = new tlsSocket();
				tlssocket.addEventListener(tlsEvent.READY, onTLSReady);
				unConfigureListeners();
				tlssocket.startTLS(socket, host, clientConfig);
				this.socket = tlssocket;
				configureListeners();
				reset();
			} catch (error:Error) {
				trace("Error in starttls: " + error);
				dispatchEvent(new StreamEvent(StreamEvent.DISCONNECTED, false, false, null));
			}
		}
		
		private function onTLSReady(e:Object):void {
			dispatchEvent(new StreamEvent(StreamEvent.TLS_READY, false, false, e.clone()));
		}
		
		private function configureListeners():void
		{
			socket.addEventListener(Event.CLOSE, closeHandler);
			socket.addEventListener(Event.CONNECT, connectHandler);
			socket.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
			
			socket.addEventListener(Event.CLOSE, disconnectHandler);
			socket.addEventListener(IOErrorEvent.IO_ERROR, disconnectHandler);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, disconnectHandler);
		}
		
		private function unConfigureListeners():void
		{
			socket.removeEventListener(Event.CLOSE, closeHandler);
			socket.removeEventListener(Event.CONNECT, connectHandler);
			socket.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			socket.removeEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
			
			socket.removeEventListener(Event.CLOSE, disconnectHandler);
			socket.removeEventListener(IOErrorEvent.IO_ERROR, disconnectHandler);
			socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, disconnectHandler);
		}
		
		private function closeHandler(event:Event):void {
			// nothing to see here ATM
		}

		private function connectHandler(event:Event):void {
			dispatchEvent(new StreamEvent(StreamEvent.CONNECTED, false, false, event.clone()));
			state['connected'] = true;
		}

		private function ioErrorHandler(event:IOErrorEvent):void {
			// nothing to see here ATM
		}

		private function securityErrorHandler(event:SecurityErrorEvent):void {
			trace("securityErrorHandler: " + event);
		}

		public function socketDataHandler(event:ProgressEvent):void {
			recvBuffer();
		}
		
		public function disconnectHandler(event:Event):void {
			keep_alive_timer.stop();
			if(state['connected']) {
				state['connected'] = false;
				dispatchEvent(new StreamEvent(StreamEvent.DISCONNECTED, false, false, event.clone()));
			} else {
				dispatchEvent(new StreamEvent(StreamEvent.CONNECT_FAILED, false, false, event.clone()));
			}
		}
		
		public function send(data:String):void {
			trace("OUT: " + data);
			dispatchEvent(new StreamEvent(StreamEvent.COMM_OUT, false, false, null, data));
			try {
				socket.writeUTFBytes(data);
				socket.flush();
			} catch (error:Error) {
				trace("Error writing to socket: " + error);
				dispatchEvent(new StreamEvent(StreamEvent.DISCONNECTED, false, false, null));
			}
		}
		
		public function reset():void {
			stream_started = false;
		}
		
		private function recvBuffer():void { // an ugly hack because AS3 doesn't have an asynch XML parser
			var incoming:String = socket.readUTFBytes(socket.bytesAvailable);
			var tag:Array = new Array(); 
			trace("IN : " + incoming);
			dispatchEvent(new StreamEvent(StreamEvent.COMM_IN, false, false, null, incoming));
			buffer += incoming;
			if(!stream_started && buffer) { // if we're expecting a start of stream
				if(buffer.search("\\?>") != -1) { // if there's an xml header
					buffer = buffer.substring(buffer.search("\\?>") + 2) // strip off the xml header
				}
				tag = getTag.exec(buffer); // grab the tag
				if(tag && tag[0].search('stream') > -1) // confirm it really is a start of stream tag
				{
					// proccess stream
					stream_tag = tag[0];
					stream_string = "<" + buffer.substring(buffer.search(tag[0]), buffer.search('>')) + ">";
					buffer = buffer.substring(buffer.search('>') + 1); // yoink
					stream_started = true;
				}
			}
			var gotfulltag:Boolean = true;
			while(gotfulltag) {
				tag = getTag.exec(buffer);
				if(tag) {
					var completeXML:RegExp = new RegExp("(\<" + tag[0] + "([^(\>)]+?)(/\>))|((\<" + tag[0] + "(.+?)\</" + tag[0] + "\>)+?)", "s"); // pull out tag with this TODO:account for CDATA
					var xmlstr:Object = completeXML.exec(buffer);
					if(xmlstr) {
						buffer = buffer.substring(buffer.search(xmlstr[0]) + xmlstr[0].length);
						callback(stream_string + xmlstr[0] + "</" + stream_tag + ">");
					} else {
						gotfulltag = false;
					}
				} else {
					gotfulltag = false;
				}
			}
		}
	}
}