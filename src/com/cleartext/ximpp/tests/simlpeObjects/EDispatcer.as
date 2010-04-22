package com.cleartext.ximpp.tests.simlpeObjects
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;

	public class EDispatcer extends EventDispatcher
	{
		public var str:String = "0123456789";

		public function EDispatcer(target:IEventDispatcher=null)
		{
			super(target);
		}
		
	}
}