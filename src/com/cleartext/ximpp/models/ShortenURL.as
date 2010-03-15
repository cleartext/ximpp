package com.cleartext.ximpp.models
{
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	 
	public class ShortenURL
	{
		private var apiKey:String = "R_98fd2ecec7f11a6697af48f3207bd073";
		private var userName:String = "cleartext";
		private var apiVersion:String = "2.0.1";

		public var longURL:String = ''
		private var resultReturn:Function;
		
		public function ShortenURL()
		{
		}

		public function call(URL:String, resultHandler:Function):void
		{
			resultReturn = resultHandler;
			longURL = URL;
			var htService:HTTPService = new HTTPService();
			htService.method = 'GET';
			htService.resultFormat = 'array';
			htService.url = 'http://api.bit.ly/shorten';
			 
			var params:Object = new Object();
			params.longUrl = URL;
			params.login = userName;
			params.apiKey = apiKey;
			params.version = apiVersion;
			params.format = 'xml';
			 
			htService.addEventListener(ResultEvent.RESULT, resutlHander);
			htService.send(params);
		}

		private function resutlHander(resultEV:ResultEvent):String
		{
			var shortXML:XML = new XML(resultEV.message.body);
			if(shortXML.child("errorCode").toString() == 0)
				return resultReturn(shortXML.child("results").child('nodeKeyVal').child("shortUrl").toString());
			else
				return resultReturn(longURL); 
		}
	}
}