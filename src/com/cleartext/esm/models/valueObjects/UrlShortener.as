package com.cleartext.esm.models.valueObjects
{
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	public class UrlShortener
	{
		
		public static var doNotShorten:Object = new Object();
		
		public static function alreadyShortenend(url:String):Boolean
		{
			if(!url)
				return true;
				
			return doNotShorten.hasOwnProperty(url);
		}
		public static function addUrl(url:String):void
		{
			doNotShorten[url] = true;
		}
		
		public static const CTR_IM:String = "ctr.im";
		public static const BIT_LY:String = "bit.ly";
		public static const IS_GD:String = "is.gd";
		
		public static const types:Array = [CTR_IM, BIT_LY, IS_GD];
				
		public var longUrl:String = '';
		public var resultHandler:Function;
		public var service:String;
		
		public function UrlShortener()
		{
		}

		public function shorten(longUrl:String, service:String, resultHandler:Function):void
		{
			if(UrlShortener.alreadyShortenend(longUrl))
				resultHandler(longUrl, true);
			
			this.service = service;
			this.resultHandler = resultHandler;
			this.longUrl = longUrl;
			
			var srv:HTTPService = new HTTPService();
			var params:Object = new Object();
			srv.addEventListener(FaultEvent.FAULT, faultHandler);
			srv.addEventListener(ResultEvent.RESULT, callResultHandler);
			
			var escapedUrl:String = encodeURIComponent(longUrl);
			
			switch (service)
			{
				case CTR_IM :
					srv.method = 'GET';
					srv.url = 'http://api.bit.ly/v3/shorten?' + 
							'login=cleartext&' + 
							'apiKey=R_98fd2ecec7f11a6697af48f3207bd073&' + 
							'uri=' + escapedUrl + '&' + 
							'format=xml';
					break;

				case BIT_LY :
					srv.method = 'GET';
					srv.url = 'http://api.bit.ly/v3/shorten?' + 
							'login=cleartext2&' + 
							'apiKey=R_cd4b248031048fdf982829e9b43138c5&' + 
							'uri=' + escapedUrl + '&' + 
							'format=xml';
					break;

				case IS_GD :
					srv.method = 'GET';
					srv.url = 'http://is.gd/api.php?longurl=' + escapedUrl;
					break;
			}
			srv.send();
		}
		
		private function faultHandler(event:FaultEvent):String
		{
			UrlShortener.addUrl(longUrl);
			return resultHandler(longUrl, true); 
		}

		private function callResultHandler(event:ResultEvent):String
		{
			var shortUrl:String;

			switch(service)
			{
				case CTR_IM :
				case BIT_LY :
					var shortXML:Object = new XML(event.message.body);
					if(shortXML)
						shortUrl = shortXML.data.url;
					break;

				case IS_GD :
					var tempStr:String = event.message.body.toString();
					if(tempStr.indexOf("Error: ") != 0)
						shortUrl = tempStr;
					break;
			}
			
			if(shortUrl)
			{
				// add the short url so we don't try to shorten again
				UrlShortener.addUrl(shortUrl);
				return resultHandler(shortUrl);
			}
			else
			{
				// there was a problem, so add the long url so we don't try to shorten again
				UrlShortener.addUrl(longUrl);
				return resultHandler(longUrl, true); 
			}
		}
	}
}