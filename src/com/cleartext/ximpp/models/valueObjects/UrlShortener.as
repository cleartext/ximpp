package com.cleartext.ximpp.models.valueObjects
{
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	public class UrlShortener
	{
		
		public static const CTR_IM:String = "ctr.im";
		public static const BIT_LY:String = "bit.ly";
		public static const IS_GD:String = "is.gd";
		
		public static const types:Array = [CTR_IM, BIT_LY, IS_GD];
		
		public static function isLong(url:String):Boolean
		{
			for each(var type:String in types)
				if(url.indexOf("http://" + type) == 0)
					return false;

			return true;
		}
		
		public var longURL:String = ''
		public var resultHandler:Function;
		public var service:String;
		
		public function UrlShortener()
		{
		}

		public function shorten(longUrl:String, service:String, resultHandler:Function):void
		{
			this.service = service;
			this.resultHandler = resultHandler;
			this.longURL = longUrl;
			
			var srv:HTTPService = new HTTPService();
			var params:Object = new Object();

			switch (service)
			{
				case CTR_IM :
					srv.method = 'GET';
					srv.resultFormat = 'array';
					srv.url = 'http://api.bit.ly/shorten';
					 
					params.longUrl = longUrl;
					params.login = "cleartext";
					params.apiKey = "R_98fd2ecec7f11a6697af48f3207bd073";
					params.version = "2.0.1";
					params.format = 'xml';
					 
					srv.addEventListener(ResultEvent.RESULT, callResultHandler);
					srv.send(params);
					return;

				case BIT_LY :
					srv.method = 'GET';
					srv.resultFormat = 'array';
					srv.url = 'http://api.bit.ly/shorten';
					 
					params.longUrl = longUrl;
					params.login = "cleartext2";
					params.apiKey = "R_cd4b248031048fdf982829e9b43138c5";
					params.version = "2.0.1";
					params.format = 'xml';
					 
					srv.addEventListener(ResultEvent.RESULT, callResultHandler);
					srv.send(params);
					return;

				case IS_GD :
					srv.method = 'GET';
					srv.url = 'http://is.gd/api.php?longurl=' + longUrl;
					srv.addEventListener(ResultEvent.RESULT, callResultHandler);
					srv.send();
					return;
					
			}
		}

		private function callResultHandler(event:ResultEvent):String
		{
			var shortUrl:String;

			switch(service)
			{
				case CTR_IM :
					var shortCtrimXML:XML = new XML(event.message.body);
					if(shortCtrimXML.child("errorCode").toString() == 0)
						shortUrl = shortCtrimXML.child("results").child('nodeKeyVal').child("shortUrl").toString();
					break;

				case BIT_LY :
					var shortXML:XMLList = new XML(event.message.body).child("results").child('nodeKeyVal');
					if(shortXML.child("errorCode").toString() == 0)
						shortUrl = shortXML.child("shortUrl").toString();
					break;

				case IS_GD :
					var tempStr:String = event.message.body.toString();
					if(tempStr.indexOf("Error: ") != 0)
						shortUrl = tempStr;
					break;
			}
			
			if(shortUrl)
				return resultHandler(shortUrl);
			else
				return resultHandler(longURL); 
		}
	}
}