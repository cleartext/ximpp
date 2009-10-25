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

	public class XMPPEvent extends Event
	{
		public static const MESSAGE:String = "xmpp-message";
		public static const MESSAGE_MUC:String = "xmpp-message-muc";
		public static const PRESENCE:String = "xmpp-presence";
		public static const SESSION:String = "xmpp-session";
		public static const SECURE:String = "xmpp-secure";
		public static const AUTH_FAILED:String = "xmpp-unauthed";
		public static const AUTH_SUCCEEDED:String = "xmpp-authed";
		public static const PRESENCE_AVAILABLE:String = "xmpp-presence-available";
		public static const PRESENCE_UNAVAILABLE:String = "xmpp-presence-unavailable";
		public static const PRESENCE_ERROR:String = "xmpp-presence-error";
		public static const PRESENCE_SUBSCRIBE:String = "xmpp-presence-subscribe";
		public static const ROSTER_ITEM:String = "xmpp-roster-item";
		public static const ROSTER_ERROR:String = "xmpp-roster-error";
		public static const BOUND:String = "xmpp-jid-bound";
		
		public var stanza:Object;
		public function XMPPEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, stanza:Object=null)
		{
			this.stanza = stanza;
			super(type, bubbles, cancelable);
		}
		
	}
}