package com.cleartext.ximpp.models
{
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	public class XimppUtils
	{
		public static function avatarToString(avatar:BitmapData, size:uint=64):String
		{
			if(!avatar)
				return null;
			
			var byteArray:ByteArray = avatar.getPixels(new Rectangle(0,0,size,size));
			var base64Enc:Base64Encoder = new Base64Encoder();
			base64Enc.encodeBytes(byteArray);
			var result:String = base64Enc.flush();
			//trace(result);
			return result;
		}
		
		public static function stringToAvatar(avatarStr:String, size:uint=64):BitmapData
		{
			if(!avatarStr)
				return null;
			
			var base64Dec:Base64Decoder = new Base64Decoder();
			base64Dec.decode(avatarStr);

			var byteArray:ByteArray = base64Dec.toByteArray();

			var result:BitmapData = new BitmapData(size,size);
			result.setPixels(new Rectangle(0,0,size,size), byteArray);
			return result;
		}

	}
}