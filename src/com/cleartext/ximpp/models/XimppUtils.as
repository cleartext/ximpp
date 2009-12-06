package com.cleartext.ximpp.models
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	import mx.controls.Image;
	import mx.graphics.codec.PNGEncoder;
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	public class XimppUtils
	{
		public static function avatarToString(avatar:BitmapData):String
		{
			if(!avatar)
				return null;
			
			var byteArray:ByteArray = new PNGEncoder().encode(avatar);
			var base64Enc:Base64Encoder = new Base64Encoder();
			base64Enc.encodeBytes(byteArray);
			var result:String = base64Enc.flush();
			return result;
		}
		
		public static function stringToAvatar(avatarStr:String, completeHandler:Function):void
		{
			if(!avatarStr)
				return;
			
			var base64Dec:Base64Decoder = new Base64Decoder();
			base64Dec.decode(avatarStr);
			var byteArray:ByteArray = base64Dec.toByteArray();

			var image:Image = new Image();
			image.load(byteArray);
			image.addEventListener(Event.COMPLETE, completeHandler, false, 0, true);
		}

	}
}