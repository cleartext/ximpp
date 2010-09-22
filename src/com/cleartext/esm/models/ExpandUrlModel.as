package com.cleartext.esm.models
{
	import com.adobe.serialization.json.JSON;
	import com.cleartext.esm.events.LinkEvent;
	import com.cleartext.esm.models.utils.ContextLoader;
	import com.cleartext.esm.models.utils.ContextURLLoader;
	
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.getTimer;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.Base64Encoder;
	
	import org.swizframework.Swiz;
	
	public class ExpandUrlModel extends EventDispatcher
	{
		private var idCounter:int = 0;
		
		public function ExpandUrlModel()
		{
			super();
		}

		public function checkUrl(url:String):int
		{
			var loader:ContextURLLoader = new ContextURLLoader();
			loader.context = ++idCounter;
			loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, httpStatusHandler);

			var request:URLRequest = new URLRequest(url);
			request.method = URLRequestMethod.HEAD
			request.followRedirects = false;
			try{
				loader.load(request);
			}
			catch(error:Error)
			{
				// do nothing;
			}
			return idCounter;
		}
		
		private function httpStatusHandler(event:HTTPStatusEvent):void
		{
			var id:int = event.target.context;
			if(event.status != 301)
			{
				Swiz.dispatchEvent(new LinkEvent(LinkEvent.LINK_RESULT, "", LinkEvent.OK, id));
			}
			else
			{
				for each(var header:URLRequestHeader in event.responseHeaders)
				{
					if(header.name == "Location")
					{
						Swiz.dispatchEvent(new LinkEvent(LinkEvent.LINK_RESULT, header.value, LinkEvent.REDIRECT, id));
						break;
					}
				}
			}
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void
		{
			var id:int = event.target.context;
			Swiz.dispatchEvent(new LinkEvent(LinkEvent.LINK_RESULT, "Security Error", LinkEvent.ERROR, id));
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void
		{
			var id:int = event.target.context;
			Swiz.dispatchEvent(new LinkEvent(LinkEvent.LINK_RESULT, "IO Error", LinkEvent.ERROR, id));
		}

	}
}