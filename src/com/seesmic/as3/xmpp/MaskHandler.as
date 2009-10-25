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

	
	public class MaskHandler extends XMLHandler {
		public var searchXML:XML;

		
		public function MaskHandler(search:String, pointer:Function=null, use_once:Boolean=false) {
			searchXML = XML(search);
			super(search, pointer, use_once);
		}
		
		override public function match(xdoc:XML):Boolean {
			return nodeCompare(searchXML, xdoc)
			//for each(var element:XMLNode in searchXML.childNodes) {
		}
		
		private function nodeCompare(searchNode:XML, findNode:XML):Boolean {
			//trace(findNode.nodeName);
			if(searchNode.localName() != findNode.localName()) {
				//trace(searchNode.nodeName + "!=" + curnode);
				return false;
			}
			if(findNode.namespace() != searchNode.namespace()) {
				return false;
			}
			if(searchNode.text() && findNode.text() != searchNode.text()) {
				return false;
			}
			for each(var attr:Object in searchNode.attributes) {
				//trace ("**" + attr); // um, that's not helpful
			}
			var found:Boolean = false;
			for each(var searchSub:XML in searchNode.children()) {
				for each(var findSub:XML in findNode.children()) {
					if(nodeCompare(searchSub, findSub)) {
						found = true;
						break;
					}
				}
				if(!found) return false;
				found = false;
			}
			//trace("match!");
			return true;
		}
	}
}