package com.cleartext.ximpp.models.valueObjects
{
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	public class UrlShortener
	{
		
		public static const BIT_LY:String = "bit.ly";
		public static const IS_GD:String = "is.gd";
		
		public static const types:Array = [BIT_LY, IS_GD];
		
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
				case BIT_LY :
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
			switch(service)
			{
				case BIT_LY :
					var shortXML:XML = new XML(event.message.body);
					if(shortXML.child("errorCode").toString() == 0)
						return resultHandler(shortXML.child("results").child('nodeKeyVal').child("shortUrl").toString());
					break;
				case IS_GD :
					var shortURL:String = event.message.body.toString();
					if(shortURL.indexOf("Error: ") != 0)
						return resultHandler(shortURL);
					break;
			}
			
			return resultHandler(longURL); 
		}
	}
}