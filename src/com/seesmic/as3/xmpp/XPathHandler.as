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
	
	public class XPathHandler extends XMLHandler
	{
		private var splitnodes:RegExp = new RegExp("{[^}]*}[a-zA-Z]+");
		public function XPathHandler(search:String, pointer:Function=null, use_once:Boolean=false)
		{
			super(search, pointer, use_once);
		}
		
		public override function match(xdoc:XML):Boolean {
			var newsearch:String = search;
			var xpathnodes:Array = new Array();
			while(true) {
				var xpathnode:String = splitnodes.exec(newsearch);
				if(xpathnode) {
					xpathnodes.push(xpathnode);
				} else {
					break;
				}
				newsearch = newsearch.substring(newsearch.search(xpathnode) + xpathnode.length);
			}
			return matchXPath(xpathnodes, xdoc);
		}

		public function matchXPath(xpathnodes:Array, currentNode:XML):Boolean {
			//trace('matching', xpathnodes, currentNode.localName());
			var xpathNS:String;
			var xpathName:String;
			if(xpathnodes[0].search('}') > -1) {
				var xpath:Array = xpathnodes[0].substring(1).split('}');
				xpathName = xpath[1];
				xpathNS = xpath[0];
			} else {
				xpathNS = '';
				xpathName = xpathnodes[0];
			}
			//trace(xpathNS, currentNode.namespace(), xpathName, currentNode.localName());
			if(!(xpathNS == currentNode.namespace().toString() && xpathName == currentNode.localName().toString())) {
				return false;
			}

			xpathnodes = xpathnodes.slice(1);
			var found:Boolean = false;
			if(xpathnodes.length > 0) {
				for each(var currentSub:XML in currentNode.children()) {
					if(matchXPath(xpathnodes, currentSub)) {
						found = true;
						break;
					} 
				}
				if(!found) return false;
				found = false;
			}
			return true;
		}
	}
}