package com.universalsprout.flex.components.list
{
import flash.display.DisplayObject;
import flash.events.Event;

import mx.core.UIComponent;
import mx.core.mx_internal;
import mx.managers.ILayoutManagerClient;
use namespace mx_internal;

public class NonInvalidatingUIComponent extends UIComponent
{
	private var oldWidth:Number;
	private var oldHeight:Number;
	
	public function NonInvalidatingUIComponent(initialWidth:Number=NaN, initialHeight:Number=NaN)
	{
		super();
		
		if(initialWidth)
			_width = initialWidth;
		if(initialHeight)
			_height = initialHeight;
	}
	
	override public function set width(value:Number):void
	{
        if (explicitWidth != value)
        {
            explicitWidth = value;
            invalidateSize();
        }

        if (_width != value)
        {
            invalidateProperties();
            invalidateDisplayList();

            _width = value;

            dispatchEvent(new Event("widthChanged"));
        }
	}

    override public function set height(value:Number):void
    {
        if (explicitHeight != value)
        {
            explicitHeight = value;
            invalidateSize();
        }

        if (_height != value)
        {
            invalidateProperties();
            invalidateDisplayList();

            _height = value;

            dispatchEvent(new Event("heightChanged"));
        }
    }
    
    override public function get scaleX():Number { return 1.0; }
    override public function set scaleX(value:Number):void {}

    override public function get scaleY():Number { return 1.0; }
    override public function set scaleY(value:Number):void {}

    override public function get percentWidth():Number { return NaN; }
    override public function set percentWidth(value:Number):void {}

    override public function get percentHeight():Number { return NaN; }
    override public function set percentHeight(value:Number):void {}

    override public function get explicitMinWidth():Number { return NaN; }
    override public function set explicitMinWidth(value:Number):void {}

    override public function get explicitMinHeight():Number { return NaN; }
    override public function set explicitMinHeight(value:Number):void {}

    override public function get explicitMaxWidth():Number { return NaN; }
    override public function set explicitMaxWidth(value:Number):void {}

    override public function get explicitMaxHeight():Number { return NaN; }
    override public function set explicitMaxHeight(value:Number):void {}
    
	private var _explicitWidth:Number;
    override public function get explicitWidth():Number { return _explicitWidth; }
    override public function set explicitWidth(value:Number):void { _explicitWidth=value; }

	private var _explicitHeight:Number;
    override public function get explicitHeight():Number { return _explicitHeight; }
    override public function set explicitHeight(value:Number):void { _explicitHeight=value; }
    
    //----------------------------------
    //  includeInLayout
    //----------------------------------

    private var _includeInLayout:Boolean = true;

    [Bindable("includeInLayoutChanged")]
    [Inspectable(category="General", defaultValue="true")]
    override public function get includeInLayout():Boolean
    {
        return _includeInLayout;
    }
    override public function set includeInLayout(value:Boolean):void
    {
        if (_includeInLayout != value)
        	setIncludeInLayout(value);
    }
    
    public function setIncludeInLayout(value:Boolean, noEvent:Boolean=false):void
    {
        _includeInLayout = value;

        if(!noEvent)
            dispatchEvent(new Event("includeInLayoutChanged"));
    }
    
    override public function validateSize(recursive:Boolean = false):void
    {
        if (recursive)
        {
            for (var i:int = 0; i < numChildren; i++)
            {
                var child:DisplayObject = getChildAt(i);
                if (child is ILayoutManagerClient )
                    (child as ILayoutManagerClient ).validateSize(true);
            }
        }

        if (!invalidateSizeFlag)
            return;

        invalidateSizeFlag = false;

        if (isNaN(explicitWidth) || isNaN(explicitHeight))
            measure();

       if(measuredWidth != oldWidth || measuredHeight != oldHeight)
       {
			oldWidth = measuredWidth;
			oldHeight = measuredHeight;
	        invalidateDisplayList();
       }
    }
    
    override protected function commitProperties():void
    {
    }
    
    override mx_internal function setUnscaledWidth(value:Number):void
    {
    	trace("[NonInvalidatingUIComponent].setUnscaledWidth()");
    }

    override mx_internal function setUnscaledHeight(value:Number):void
    {
    	trace("[NonInvalidatingUIComponent].setUnscaledHeight()");
    }
}
}