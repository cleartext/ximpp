////////////////////////////////////////////////////////////////////////////////
//
//	Copyright (c) 2007 Tink Ltd | http://www.tink.ws
//	
//	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//	documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
//	the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
//	to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//	
//	The above copyright notice and this permission notice shall be included in all copies or substantial portions
//	of the Software.
//	
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO 
//	THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.
//
////////////////////////////////////////////////////////////////////////////////

package ws.tink.flex.controls.positionedTabBarClasses
{
	
	
	import mx.controls.tabBarClasses.Tab;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
	
	import ws.tink.flex.skins.halo.PositionedTabSkin;
	
	
	[Style(name="position", type="String", enumeration="top,bottom,left,right", inherit="no")]
	
	
	public class PositionedTab extends Tab
	{
		
		
		//--------------------------------------------------------------------------
	    //
	    //  Constructor
	    //
	    //--------------------------------------------------------------------------
	    
	    /**
	     *  Constructor.
	     */
		public function PositionedTab()
		{
			super();
		}
		
		
		
		//--------------------------------------------------------------------------
	    //
	    //  Setup default styles.
	    //
	    //--------------------------------------------------------------------------
	    
		private static var defaultStylesSet				: Boolean = setDefaultStyles();
		
		/**
	     *  @private
	     */
		private static function setDefaultStyles():Boolean
		{
			var style:CSSStyleDeclaration = StyleManager.getStyleDeclaration( "PositionedTab" );
			
		    if( !style )
		    {
		        style = new CSSStyleDeclaration();
		        StyleManager.setStyleDeclaration( "PositionedTab", style, true );
		    }
		    
		    if( style.defaultFactory == null )
	        {
	        	style.defaultFactory = function():void
	            {
	            	this.position = "top";
	            	this.skin = PositionedTabSkin;				
	            };
	        }

		    return true;
		}
	}
}