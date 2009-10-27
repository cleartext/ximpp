package com.arc90.flexlib.containers
{
import flash.events.Event;
import flash.events.MouseEvent;
import flash.utils.getQualifiedClassName;

import mx.containers.Panel;
import mx.controls.Button;
import mx.core.EdgeMetrics;
import mx.core.FlexVersion;
import mx.core.ScrollPolicy;
import mx.core.UITextField;
import mx.core.mx_internal;
import mx.effects.Resize;
import mx.events.EffectEvent;
import mx.logging.ILogger;
import mx.logging.Log;
import mx.styles.CSSStyleDeclaration;
import mx.styles.StyleManager;
import mx.styles.StyleProxy;
	
use namespace mx_internal;

//--------------------------------------
//  Events
//--------------------------------------

/**
 *  Dispatched when the user collapses the panel.
 *
 *  @eventType minimize
 */
[Event(name="minimize", type="flash.events.Event")]

/**
 *  Dispatched when the user expands the panel.
 *
 *  @eventType restore
 */
[Event(name="restore", type="flash.events.Event")]

//--------------------------------------
//  Styles
//--------------------------------------

/**
 *  The collapse button disabled skin.
 *
 *  @default CollapseButtonDisabled
 */
[Style(name="collapseButtonDisabledSkin", type="Class", inherit="no")]

/**
 *  The collapse button down skin.
 *
 *  @default CollapseButtonDown
 */
[Style(name="collapseButtonDownSkin", type="Class", inherit="no")]

/**
 *  The collapse button over skin.
 *
 *  @default CollapseButtonOver
 */
[Style(name="collapseButtonOverSkin", type="Class", inherit="no")]

/**
 *  The collapse button up skin.
 *
 *  @default CollapseButtonUp
 */
[Style(name="collapseButtonUpSkin", type="Class", inherit="no")]

/**
 *  The collapse button default skin.
 *
 *  @default null
 */
[Style(name="collapseButtonSkin", type="Class", inherit="no", states="up, over, down, disabled")]

/**
 *  The collapse effect duration.
 *
 *  @default 250
 */
[Style(name="collapseDuration", type="Number", inherit="no")]

public class CollapsiblePanel extends Panel
{
	//--------------------------------------------------------------------------
    //
    //  Class constants
    //
    //--------------------------------------------------------------------------
	
	//--------------------------------------------------------------------------
    //
    //  Class variables
    //
    //--------------------------------------------------------------------------
	
	/**
	 * @private
	 * Logger for this class.
	 */
	private static var logger:ILogger = Log.getLogger("com.arc90.flexlib.containers.CollapsiblePanel");
	
	private static var classConstructed:Boolean = constructClass();
	
	[Embed(source="/assets/Assets.swf", symbol="CollapseButtonDisabled")] 
	private static var collapseButtonDisabledSkin:Class;
	
	[Embed(source="/assets/Assets.swf", symbol="CollapseButtonDown")] 
	private static var collapseButtonDownSkin:Class;
	
	[Embed(source="/assets/Assets.swf", symbol="CollapseButtonOver")] 
	private static var collapseButtonOverSkin:Class;
	
	[Embed(source="/assets/Assets.swf", symbol="CollapseButtonUp")]
	private static var collapseButtonUpSkin:Class;
			
	//--------------------------------------------------------------------------
    //
    //  Class methods
    //
    //--------------------------------------------------------------------------
    
    private static function constructClass():Boolean
    {
    	if(!StyleManager.getStyleDeclaration("CollapsiblePanel"))
    	{
    		var styleDecl:CSSStyleDeclaration = new CSSStyleDeclaration();
    		styleDecl.defaultFactory = function():void
    		{
    			this.collapseButtonUpSkin = collapseButtonUpSkin;
    			this.collapseButtonDownSkin = collapseButtonDownSkin;
    			this.collapseButtonOverSkin = collapseButtonOverSkin;
    			this.collapseButtonDisabledSkin = collapseButtonDisabledSkin;
    			this.collapseDuration = 250;
    		}
    		StyleManager.setStyleDeclaration("CollapsiblePanel", styleDecl, true);
    	}    	
    	return true;	
    }   
     
	//--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
	
	/**
	 * @private
	 * Internal component: Collapse Button.
	 */
//	private var collapseButton:Button;
	
	/**
	 * @private
	 * Height of the component before collapse.
	 */
	private var expandedHeight:Number;
	
	/**
	 * @private
	 * The transition effect from collapsed to expanded and back.
	 */
	private var tween:Resize = new Resize(this);	 
	
	/**
	 * @private
	 * The original verticalScrollPolicy.
	 */
	private var originalVScrollPolicy:String;
	
	//--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
	
    /**
     *  Constructor.
     */
	public function CollapsiblePanel()
	{
		super();
		
		tween.addEventListener(EffectEvent.EFFECT_END, tween_effectEndHandler);
	}

	//--------------------------------------------------------------------------
    //
    //  Overridden properties
    //
    //--------------------------------------------------------------------------
	
	//----------------------------------
    //  collapseButtonStyleFilters
    //----------------------------------
	
	/**
	 * @private
	 * Storage for the collapseButtonStyleFilters property.
	 */
	private static var _collapseButtonStyleFilters:Object = 
	{
		"collapseButtonUpSkin" : "collapseButtonUpSkin", 
		"collapseButtonOverSkin" : "collapseButtonOverSkin",
		"collapseButtonDownSkin" : "collapseButtonDownSkin",
		"collapseButtonDisabledSkin" : "collapseButtonDisabledSkin",
		"collapseButtonSkin" : "collapseButtonSkin",
		"repeatDelay" : "repeatDelay",
		"repeatInterval" : "repeatInterval"
    };
    
 	/**
     *  The set of styles to pass from the Panel to the collapse button.
     *  @see mx.styles.StyleProxy
     */
	protected function get collapseButtonStyleFilters():Object
	{
		return _collapseButtonStyleFilters;
	}
	
	//----------------------------------
    //  collapsed
    //----------------------------------
	
	/**
	 * @private
	 * Storage for the collapsed property.
	 */
	private var _collapsed:Boolean = false;
	
	/**
	 * @private
	 * Dirty flag for the collapse property.
	 */
	private var collapsedChanged:Boolean = false;
	
	/**
	 * If <code>true</code>, the component is in its minimized state.
	 */
	public function get collapsed():Boolean
	{
		return _collapsed;
	}
	
	/**
	 * @private
	 */
	public function set collapsed(value:Boolean):void
	{
		if(_collapsed == value)
			return;
			
		_collapsed = value;
		collapsedChanged = true;
		
		invalidateSize();
		invalidateDisplayList();		
	}
    
    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //
    //--------------------------------------------------------------------------
	
	/**
	 * @private
	 */
	override protected function createChildren():void
	{
		// Prevent the panel from wasting cycles/memory on the close button
		if(!closeButton)
		{
			closeButton = new Button();
		}
		
		super.createChildren();
		
		// Configure the titleBar to receive double-click events.
		if(titleBar)
		{
			titleBar.doubleClickEnabled = true;
			titleBar.addEventListener(MouseEvent.CLICK, titleBar_doubleClickHandler);
		}
	}
	
	/**
	 * @private
	 */
	override protected function layoutChrome(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.layoutChrome(unscaledWidth, unscaledHeight);
		
		var em:EdgeMetrics = EdgeMetrics.EMPTY;
        var bt:Number = getStyle("borderThickness"); 
        if (getQualifiedClassName(this.border) == "mx.skins.halo::PanelSkin" &&
        	getStyle("borderStyle") != "default" && bt) 
        {
        	em = new EdgeMetrics(bt, bt, bt, bt);
        }
        
		var bm:EdgeMetrics =
        	FlexVersion.compatibilityVersion < FlexVersion.VERSION_3_0 ?
        	borderMetrics :
        	em;      
        
        var headerHeight:int = getHeaderHeight();
        var x:Number = bm.left;
        var y:Number = bm.top;
        
		var h:Number;
		var offset:Number;
		var rightOffset:Number = 10;
		
		if (FlexVersion.compatibilityVersion < FlexVersion.VERSION_3_0)
        	h = titleTextField.nonZeroTextHeight;
        else 
        	h = titleTextField.getUITextFormat().measureText(titleTextField.text).height;
        offset = (headerHeight - h) / 2;
        
        var titleX:Number = x + 10;
        titleTextField.move(titleX, offset - 1);
        
        var borderWidth:Number = bm.left + bm.right; 
		var statusX:Number = unscaledWidth - rightOffset - 4 -
                             borderWidth - statusTextField.textWidth;
        statusTextField.move(statusX, offset - 1);
        statusTextField.setActualSize(statusTextField.textWidth + 8,
            							statusTextField.textHeight + UITextField.TEXT_HEIGHT_PADDING);

        // Make sure the status text isn't too long.
        // We do simple clipping here.
        var minX:Number = titleTextField.x + titleTextField.textWidth + 8;
        if (statusTextField.x < minX)
        {
            // Show as much as we can.
            statusTextField.width = Math.max(statusTextField.width -
                                    (minX - statusTextField.x), 0);
            statusTextField.x = minX;
		}		
	}
	
	/**
	 * @private
	 */
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		
		if(collapsedChanged)
		{
			collapsedChanged = false;
			
			if(_collapsed)
			{
				// Store expanded values
				originalVScrollPolicy = verticalScrollPolicy;
				expandedHeight = unscaledHeight;
				
				verticalScrollPolicy = ScrollPolicy.OFF;
				tween.heightTo = getHeaderHeight();
			}	
			else
			{
				tween.heightTo = expandedHeight;
			}
			
			if(tween.isPlaying)
				tween.stop();
			
			if(getStyle("collapseDuration"))
				tween.duration = getStyle("collapseDuration") as Number;
				
			tween.hideChildrenTargets = [this];		
			tween.play();
		}
	}
	
	//--------------------------------------------------------------------------
    //
    //  Asset event handlers
    //
    //--------------------------------------------------------------------------
	
	/**
	 * @private
	 * Handles user click on the collapse button.
	 */
	private function collapseButton_clickHandler(event:MouseEvent):void
	{
		collapsed = !_collapsed;
		
		if(_collapsed)
			dispatchEvent(new Event("minimize"));
		else
			dispatchEvent(new Event("restore"));
	}
	
	/**
	 * @private
	 * Handles user double-click on the header area.
	 */
	private function titleBar_doubleClickHandler(event:MouseEvent):void
	{
		if(!enabled)
			return;
			
		collapsed = !_collapsed;
		
		if(_collapsed)
			dispatchEvent(new Event("minimize"));
		else
			dispatchEvent(new Event("restore"));
	}
	
	private function tween_effectEndHandler(event:EffectEvent):void
	{
		verticalScrollPolicy = originalVScrollPolicy;
	}
}
}