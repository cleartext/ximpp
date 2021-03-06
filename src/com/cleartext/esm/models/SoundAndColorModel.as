package com.cleartext.esm.models
{
	import com.cleartext.esm.models.utils.ContextLoader;
	
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.core.FlexGlobals;
	
	public class SoundAndColorModel
	{
		[Autowire]
		[Bindable]
		public var appModel:ApplicationModel;
		
		[Bindable]
		public var logo:Bitmap;
		
		public static const COLOR_FILE:String = "colors.xml";
		public static const LOGO_FILE:String = "logo.png";
		
		// Sound types
		public static const NEW_MESSAGE:String = "newMessage";
		public static const NEW_SOCIAL:String = "newSocial";
		public static const NEW_CONVERSATION:String = "newConversation";
		
		private static var SOUND_NAMES:Array = [NEW_MESSAGE, NEW_SOCIAL, NEW_CONVERSATION];

		private var newMessage:Sound;
		private var newSocial:Sound;
		private var newConversation:Sound;
		
		private var locks:Array = [true, true, true];

		//-------------------------------
		// Colors
		//-------------------------------

		private static var COLOR_NAMES:Array = [
			"themeColor", 
			"backgroundColor", 
			"backgroundAccent", 
			"headerColor", 
			"headerAccent", 
			"inputCanvasBorder",
			"statusAccent",
			"statusTop",
			"statusBottom",
			"statusBorder",
			"filterTop",
			"filterBottom",
			"triangleColor"];
		private static var STRING_VARS:Array = ["supportLink", "helpLink"];
		
		/** -----------------------------------------------------------------------------
		 * 
		 * TO CHANGE THE DEFAULT INSTALLED COLORS AND LINKS IN THE
		 * APP, CHANGE THE FOLLOWING VALUES
		 * 
		 * ---------------------------------------------------------------------------- */

		// default 0xf7a136
		public var themeColor:uint = 0xf7a136;
		// default 0x000000
		public var backgroundColor:uint = 0x000000;
		// default 0x3e443f
		public var backgroundAccent:uint = 0x3e443f;
		// default 0x000000
		public var headerColor:uint = 0x000000;
		// default 0x3e443f
		public var headerAccent:uint = 0x3e443f;
		// default 0xffffff
		public var inputCanvasBorder:uint = 0xffffff;
		// default 0x909090
		public var statusAccent:uint = 0x909090;
		// default 0x9b9b9b
		public var statusTop:uint = 0x9b9b9b;
		// default 0xf3f3f3
		public var statusBottom:uint = 0xf3f3f3;
		// default 0xffffff
		public var statusBorder:uint = 0xffffff;
		// default 0xa1a4a7
		public var filterTop:uint = 0xa1a4a7;
		// default 0x4f5051
		public var filterBottom:uint = 0x4f5051;
		// default 0xffffff
		public var triangleColor:uint = 0xffffff;
		
		
		// default http://getsatisfaction.com/cleartext
		public var supportLink:String = 'http://getsatisfaction.com/cleartext';
		// default http://help.cleartext.net/esm
		public var helpLink:String = 'http://help.cleartext.net/esm';

		/** -----------------------------------------------------------------------------
		 * 
		 * END VARIABLE TO CHANGE
		 * 
		 * ---------------------------------------------------------------------------- */

		public function SoundAndColorModel()
		{
		}
		
		public function play(soundName:String):void
		{
			if(!appModel.settings.global.playSounds)
				return;
			
			var index:int = SOUND_NAMES.indexOf(soundName);
			if(index == -1)
				return;
			
			var sound:Sound = this[soundName] as Sound;
			if(!sound)
			{
				var file:File = File.applicationStorageDirectory.resolvePath("sounds/" + soundName + ".mp3");
				sound = new Sound(new URLRequest(file.url));
				this[soundName] = sound;
			}
			
			if(locks[index])
			{
				var chanel:SoundChannel = sound.play();
				chanel.addEventListener(Event.SOUND_COMPLETE, unlockSound);
				locks[index] = false;
			}
		}
		
		private function unlockSound(event:Event):void
		{
			var chanel:SoundChannel = event.target as SoundChannel;
			chanel.removeEventListener(Event.SOUND_COMPLETE, unlockSound);
			locks = [true, true, true];
		}
		
		public function load():void
		{
			var prefDir:File = File.applicationStorageDirectory;
			var assetsDir:File = File.applicationDirectory.resolvePath("defaults");
			
			var fileStream:FileStream = new FileStream();
			var file:File;
			var xml:XML;
			var colorName:String;
			var stringName:String;
			
			// check for logo
			file = new File(prefDir.nativePath + "/" + LOGO_FILE);
			if(!file.exists)
			{
				file = assetsDir.resolvePath(LOGO_FILE);
				file.copyTo(prefDir.resolvePath(LOGO_FILE));
			}
			loadFile(file, {type: Bitmap, property: "logo"});
			
			file = new File(prefDir.nativePath + "/sounds")
			file.createDirectory();
			
			// check for sounds
			for each(var soundName:String in SOUND_NAMES)
			{
				var soundFileName:String = soundName + ".mp3";
				file = new File(prefDir.nativePath + "/sounds/" + soundFileName);
				if(!file.exists)
				{
					file = assetsDir.resolvePath(soundFileName);
					file.copyTo(prefDir.resolvePath("sounds/" + soundFileName));
				}
			}
			
			// check for colors
			file = new File(prefDir.nativePath + "/" + COLOR_FILE);
			if(file.exists)
			{
				fileStream.open(file, FileMode.READ);
				xml = new XML(fileStream.readUTFBytes(fileStream.bytesAvailable));
				
				for each(colorName in COLOR_NAMES)
				{
					var xmlList:XMLList= xml[colorName];
					var num:Number = Number(xmlList);
					if(!isNaN(num) && xmlList.length() > 0)
						this[colorName] = num;
				}
				
				for each(stringName in STRING_VARS)
				{
					var list:XMLList = xml[stringName];
					if(list.length() > 0)
						this[stringName] = list[0];
				}
			}
			fileStream.close();
			
			// write color file - we do this every time to make sure we update any changes
			fileStream.open(File.applicationStorageDirectory.resolvePath(COLOR_FILE), FileMode.WRITE);
			fileStream.position = 0;
			fileStream.truncate();
			
			xml = <colors/>;
			for each(colorName in COLOR_NAMES)
				xml.appendChild(new XML("<" + colorName + ">" + toHex(this[colorName]) + "</" + colorName + ">"));
			
			for each (stringName in STRING_VARS)
				xml.appendChild(new XML("<" + stringName + ">" + this[stringName] + "</" + stringName + ">"));

			fileStream.writeUTFBytes(xml.toXMLString());
			fileStream.close();
		}
		
		private function loadFile(file:File, context:Object):void
		{
			var fileStream:FileStream = new FileStream();
			fileStream.addEventListener(IOErrorEvent.IO_ERROR, fileErrorHandler);
			fileStream.open(file, FileMode.READ);
			var byteArray:ByteArray = new ByteArray();
			fileStream.readBytes(byteArray);
			var loader:ContextLoader = new ContextLoader();
			loader.context = context;
			loader.loadBytes(byteArray);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderCompleteHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, fileErrorHandler);
			fileStream.close();
		}
		
		private static function toHex(value:uint):String
		{
			var hex:String = Number(value).toString(16);
			return "0x" + ("00000" + hex.toUpperCase()).substr(-6);
		}

		private function fileErrorHandler(event:IOErrorEvent):void
		{
			Alert.show(event.text, event.type);
		}
		
		private function loaderCompleteHandler(event:Event):void
		{
			var context:Object = event.target.loader.context;
			var type:Class = context.type;
			var property:String = context.property;

			this[property] = type(event.target.loader.content);
		}
	}
}