package com.cleartext.ximpp.models.valueObjects
{
	import flash.display.BitmapData;
	import flash.events.IEventDispatcher;
	
	[Bindable]
	public interface IHasAvatar extends IEventDispatcher
	{
		function get avatar():BitmapData;
		function set avatar(value:BitmapData):void

		function setAvatarString(value:String):void;
		
		function get avatarString():String;
		function set avatarString(value:String):void;
		
		function get avatarHash():String;
		function set avatarHash(value:String):void;
	}
}