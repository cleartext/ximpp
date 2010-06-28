package com.cleartext.ximpp.models.valueObjects
{
	import com.universalsprout.flex.components.list.ISproutListData;
	
	import mx.collections.ArrayCollection;
	
	[Bindable]
	public interface IBuddy extends IHasAvatar, ISproutListData, IHasStatus, IHasJid
	{
		// storred in database
		
		function get buddyId():int;
		function set buddyId(value:int):void;
		
		function get customStatus():String;
		function set customStatus(value:String):void;

		function get lastSeen():int;
		function set lastSeen(value:int):void;

		function get autoOpenTab():Boolean;
		function set autoOpenTab(value:Boolean):void;
		
		function get openTab():Boolean;
		function set openTab(value:Boolean):void;
		
		function get unreadMessages():int;
		function set unreadMessages(value:int):void;
		
		// not storred in database
		
		function get isPerson():Boolean;
		function get isGateway():Boolean;
		function get isMicroBlogging():Boolean;
		function set isMicroBlogging(value:Boolean):void;

		function get isTyping():Boolean;
		function set isTyping(value:Boolean):void;
		
		function get tempAvatarHash():String;
		function set tempAvatarHash(value:String):void;
		
		function get participants():ArrayCollection;
		
		// discovery
		
		function get features():Array;
		function get identities():Array;
		function get items():Array;
		
		// shortcuts
		
		function get host():String;
		function get username():String;
		function get fullJid():String;
		
		function toDatabaseValues(userId:int):Array;
	}
}