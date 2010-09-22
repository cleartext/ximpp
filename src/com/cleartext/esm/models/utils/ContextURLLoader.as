package com.cleartext.esm.models.utils
{
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class ContextURLLoader extends URLLoader
	{
		public var context:Object;
		
		public function ContextURLLoader(request:URLRequest=null)
		{
			super(request);
		}
	}
}