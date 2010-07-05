/*
This file is part of seesmic-as3-xmpp.
Copyright (c)2009 Seesmic, Inc

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

package com.seesmic.as3.xmpp.xep
{
	import com.seesmic.as3.xmpp.XMPP;

	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	public class Plugin extends EventDispatcher
	{
		protected var xmpp:XMPP;
		private var config:Dictionary;
		public var shortcut:String = "plugin";
		public var name:String = "Longer name";

		
		public function Plugin(config:Dictionary=null)
		{
			this.config = config;
		}
		
		public function setInstance(xmpp:XMPP):void {
			this.xmpp = xmpp
		}
		
		public function init():void {
			// override
		}
		
		
	}
}