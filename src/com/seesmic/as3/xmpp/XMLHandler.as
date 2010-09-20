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
	
	public class XMLHandler {
			public var pointer:Function;
			public var search:String;
			public var use_once:Boolean = false;
			private var enabled:Boolean = true;
			
			public function XMLHandler(search:String, pointer:Function, use_once:Boolean=false) {
				this.search = search;
				this.pointer = pointer;
				this.use_once = use_once;

			}
			
			public function match(xdoc:XML):Boolean {
				if(use_once) {
					disable();
				}
				return false;	
			}
			
			public function enable():void {
				enabled = true;
			}
			
			public function disable():void {
				enabled = false;
			}
		}
}
