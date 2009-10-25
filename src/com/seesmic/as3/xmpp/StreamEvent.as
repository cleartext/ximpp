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

package com.seesmic.as3.xmpp
{
	import flash.events.Event;

	public class StreamEvent extends Event
	{
		public static const DISCONNECTED:String = "stream-disconnected";
		public static const CONNECT_FAILED:String = "stream-connect-failed";
		public static const CONNECTED:String = "stream-connected";
		public static const TLS_READY:String = "stream-tls-ready";
		public static const COMM_IN:String = "stream-comm-in";
		public static const COMM_OUT:String = "stream-comm-out";
		
		public var parent:Event;
		public var data:String;
		
		public function StreamEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, parent:Event=null, data:String=null)
		{
			this.parent = parent;
			this.data = data;
			super(type, bubbles, cancelable);
		}
		
	}
}