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
	import flash.xml.XMLNode;
	public class IdHandler extends XMLHandler
	{
		public function IdHandler(search:String, pointer:Function, use_once:Boolean=true)
		{
			super(search, pointer, use_once);
		}
		
		public override function match(xml:XML):Boolean {
			if(xml.@id.toString() == search) {
				return true;
			}
			return false;
		}
	}
}