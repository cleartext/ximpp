package com.cleartext.esm.models.valueObjects
{
	import com.cleartext.esm.events.HasAvatarEvent;
	import com.cleartext.esm.models.XMPPModel;
	import com.cleartext.esm.models.utils.AvatarUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Matrix;
	
	import mx.controls.Image;
	
	public class MicroBloggingBuddy extends HasAvatarBase
	{
		//----------------------------------------
		//  CREATE DB STRING
		//----------------------------------------
		
		public static const CREATE_MICRO_BLOGGING_BUDDIES_TABLE:String =
			"CREATE TABLE IF NOT EXISTS microBloggingBuddies (" +
			"microBloggingBuddyId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"displayName TEXT, " +
			"userName TEXT, " +
			"jid TEXT, " + 
			"avatarUrl TEXT, " +
			"avatarHash TEXT, " +
			"avatar TEXT, " +
			"gatewayJid TEXT);";
		
		public static const TABLE_MODS:Array = [
			{name: "profileUrl", type: "TEXT"}
		];

		//----------------------------------------
		//  CONSTRUCTOR
		//----------------------------------------
		
		public function MicroBloggingBuddy()
		{
			super(null);
		}
		
		//----------------------------------------
		//  PUBLIC PROPERTIES
		//----------------------------------------
		
		// these are public so they can be set in
		// createFromDB()
		public var microBloggingBuddyId:int = -1;
		public var userName:String;
		public var gatewayJid:String;
		public var avatarUrl:String;

		//----------------------------------------
		//  DISPLAY NAME
		//----------------------------------------
		
		private var _displayName:String;
		[Bindable(event="changeSave")]
		public function get displayName():String
		{
			return _displayName;
		}
		public function set displayName(value:String):void
		{
			if(_displayName != value)
			{
				_displayName = value;
				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
			}
		}

		//----------------------------------------
		//  PROFILE URL
		//----------------------------------------
		
		private var _profileUrl:String;
		[Bindable(event="changeSave")]
		public function get profileUrl():String
		{
			return _profileUrl;
		}
		public function set profileUrl(value:String):void
		{
			if(_profileUrl != value)
			{
				_profileUrl = value;
				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
			}
		}
		
		//----------------------------------------
		//  OVERRIDEN PROPERTIES FROM HAS AVATAR BASE
		//----------------------------------------
		
		override public function get nickname():String
		{
			return displayName + " (@" + userName + ")";
		}
		
		override public function get jid():String
		{
			return (super.jid) ? super.jid : userName + "@" + gatewayJid;
		}

		//--------------------------------------------------
		//
		//  AVATAR METHODS
		//
		//--------------------------------------------------		

		//----------------------------------------
		//  SET AVATAR URL
		//----------------------------------------
		
		public function setAvatarUrl(url:String):void
		{
			if(avatarUrl != url || (!avatar && url))
			{
				avatarUrl = url;
				avatar = null;
				var image:Image = new Image();
				image.addEventListener(Event.COMPLETE, imageCompleteHandler);
				image.load(avatarUrl);
			}
		}
		
		//----------------------------------------
		//  IMAGE COMPLETE HANDLER
		//----------------------------------------
		
		private function imageCompleteHandler(event:Event):void
		{
			var avatarSize:Number = 48;
			
			var image:Image = event.target as Image;
			var bitmap:Bitmap = Bitmap(image.content);
			image.removeEventListener(Event.COMPLETE, imageCompleteHandler);
			
			// if the bitmap is smaller than the AVATAR_SIZE, then scale it down
			// otherwise, just draw at the size we got it
			var scale:Number = avatarSize / Math.max(bitmap.width, bitmap.height, avatarSize);
			var matrix:Matrix = new Matrix(scale, 0, 0, scale);

			var bmd:BitmapData = new BitmapData(Math.min(bitmap.width*scale, avatarSize), Math.min(bitmap.height*scale, avatarSize));
			bmd.draw(bitmap, matrix);
			
			avatar = bmd;
			avatarString = AvatarUtils.avatarToString(avatar);
		}

		//----------------------------------------
		//  SET JID AND HASH
		//----------------------------------------
		
		public function setJidAndHash(newJid:String, hash:String, xmpp:XMPPModel):void
		{
			jid = newJid;

			if(avatarHash != hash || (!avatar && hash && jid))
			{
				avatarHash = hash;
				avatar = null;
				xmpp.getAvatarForMBlogBuddy(jid);
			}
		}
		
		//--------------------------------------------------
		//
		//  DATABASE METHODS
		//
		//--------------------------------------------------		

		//----------------------------------------
		//  CREATE FROM DATABASE
		//----------------------------------------
		
		public static function createFromDB(obj:Object):MicroBloggingBuddy
		{
			var newMicroBloggingBuddy:MicroBloggingBuddy = new MicroBloggingBuddy();
			
			newMicroBloggingBuddy.microBloggingBuddyId = obj["microBloggingBuddyId"];
			newMicroBloggingBuddy.displayName = obj["displayName"];
			newMicroBloggingBuddy.userName = obj["userName"];
			newMicroBloggingBuddy.jid = obj["jid"];
			newMicroBloggingBuddy.avatarUrl = obj["avatarUrl"];
			newMicroBloggingBuddy.avatarHash = obj["avatarHash"];
			newMicroBloggingBuddy.gatewayJid = obj["gatewayJid"];
			newMicroBloggingBuddy.avatarString = obj["avatar"];
			newMicroBloggingBuddy.profileUrl = obj["profileUrl"];
			
			return newMicroBloggingBuddy;
		}
		
		//----------------------------------------
		//  CREATE DATABASE VALUES
		//----------------------------------------
		
		public function toDatabaseValues():Array
		{
			return [
				new DatabaseValue("displayName", displayName),
				new DatabaseValue("userName", userName),
				new DatabaseValue("jid", super.jid),
				new DatabaseValue("avatarUrl", avatarUrl),
				new DatabaseValue("avatarHash", avatarHash),
				new DatabaseValue("avatar", AvatarUtils.avatarToString(avatar)),
				new DatabaseValue("gatewayJid", gatewayJid),
				new DatabaseValue("profileUrl", profileUrl)
				];
		}

	}
}