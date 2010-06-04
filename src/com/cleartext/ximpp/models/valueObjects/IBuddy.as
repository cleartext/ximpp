package com.cleartext.ximpp.models.valueObjects
{
	import flash.display.BitmapData;
	import flash.events.IEventDispatcher;
	
	public interface IBuddy extends IEventDispatcher
	{
		function get nickName():String
		
		function get jid():String;
		
		function get avatar():BitmapData;
		function set avatar(value:BitmapData):void

		function get avatarString():String;
		function set avatarString(value:String):void;
		
		function get isMicroBlogging():Boolean;
		function get isGroup():Boolean;
		function get isGateway():Boolean;
		function get isChatRoom():Boolean;
		
	}
}