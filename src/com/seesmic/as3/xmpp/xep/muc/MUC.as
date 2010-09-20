package com.seesmic.as3.xmpp.xep.muc
{
	import com.seesmic.as3.xmpp.xep.Plugin;
	
	import flash.utils.Dictionary;

	public class MUC extends Plugin
	{
		public var rooms:Array = [];
		
		public function MUC(config:Dictionary=null)
		{
			super(config);
			this.name = "Multi-User Chat (XEP-0045)";
			this.shortcut = "muc";
		}
		
		public override function init():void {
			trace("Loaded MUC Plugin");
			//xmpp.addHandler(new XPathHandler("{jabber:client}message/{jabber:client}body", messageEventHandler));
			//xmpp.addHandler(new XPathHandler("{jabber:client}message/{http://jabber.org/protocol/pubsub#event}event/{http://jabber.org/protocol/pubsub#event}items/{http://jabber.org/protocol/pubsub#event}retract", retractEventHandler));
		}
		
		public function joinRoom(server:String, room:String, nick:String):Boolean {
			var pto:String = room + '@' + server + '/' + nick;
			xmpp.sendPresence(null, null, null, pto);
			rooms.push(pto);
			return true;
		}
		
		public function leaveRoom(server:String, room:String, nick:String):Boolean {
			var pto:String = room + '@' + server + '/' + nick;
			xmpp.sendPresence(null, 'unavailable', null, pto);
			rooms.splice(rooms.indexOf(pto), 1);
			return true;
		}
		
		public function sendMessage(server:String, room:String, msg:String, subject:String=null):void {
			var tojid:String = room + '@' + server;
			xmpp.sendMessage(tojid, msg, subject, 'groupchat');
		}
		
	}
}