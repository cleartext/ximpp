package com.cleartext.ximpp.models
{
	import com.adobe.serialization.json.JSON;
	import com.cleartext.ximpp.events.LinkEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.getTimer;
	
	import mx.rpc.events.FaultEvent;
	import mx.utils.Base64Encoder;
	
	import org.swizframework.Swiz;
	
	public class WebRootModel extends EventDispatcher
	{
		private var idCounter:int = 0;
		private var startTime:int;
		
		public function WebRootModel()
		{
			super();
		}

		public function checkUrl(url:String):int
		{
			var request:URLRequest = new URLRequest();
			request.url = "http://72.5.172.35:3128/wwss_url_checker";
			request.method = URLRequestMethod.POST;

			var encoder:Base64Encoder = new Base64Encoder();        
			encoder.encode("test@tagged.com:wrtest");
			
			var authHeader:URLRequestHeader = new URLRequestHeader("Authorization", "Basic " + encoder.toString());
			request.requestHeaders.push(authHeader);
			request.data = '{"type":3,"ver":1,"urls":[{"id":' + ++idCounter + ',"url":"' + url + '"}]}';
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(FaultEvent.FAULT, traceHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, traceHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, traceHandler);

			loader.addEventListener(Event.COMPLETE, completeHandler);
			loader.load(request);
			
			startTime = getTimer();
			return idCounter;
		}
		
		private function completeHandler(event:Event):void
		{
			var loader:URLLoader = event.target as URLLoader;
			var json:Object = JSON.decode(loader.data.toString());
			var result:Object;
			
			if(json.urls && json.urls.length > 0)
			{
				result = json.urls[0];
				result.milliseconds = getTimer() - startTime;
				
//				output.text += "ID:\t\t\t" + val.id + "\n";
//				output.text += "TIME:\t\t\t" + (getTimer() - startTime)/1000 + " seconds" + "\n";
//				output.text += "REPUTATION:\t" + val.reputation + "\n";
//				output.text += "CATEGORY:\t" + val.url_category + "\n";
//				output.text += "REDIRECT:\t" + val.redirected_to + "\n\n";
			}
			else
			{
				result = json;
			}

			Swiz.dispatchEvent(new LinkEvent(LinkEvent.LINK_RESULT, "", result));
		}
		
		private function traceHandler(event:Event):void
		{
			var loader:URLLoader = event.target as URLLoader;
			var json:Object = JSON.decode(loader.data.toString());
			Swiz.dispatchEvent(new LinkEvent(LinkEvent.LINK_RESULT, "", json));
		}

	}
}