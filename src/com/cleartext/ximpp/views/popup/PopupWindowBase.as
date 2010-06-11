package com.cleartext.ximpp.views.popup
{
	import com.cleartext.ximpp.models.SoundAndColorModel;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import mx.containers.ControlBar;
	import mx.containers.TitleWindow;
	import mx.controls.Button;
	import mx.controls.List;
	import mx.controls.TextInput;
	import mx.controls.ToolTip;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.ToolTipManager;

	public class PopupWindowBase extends TitleWindow
	{
		[Autowire]
		public var soundAndColor:SoundAndColorModel;

		public var showCancelButton:Boolean = true;
		
		protected var errorMessageToolTips:Dictionary = new Dictionary();

		private var _isValid:Boolean = false;
		public function get isValid():Boolean
		{
			return _isValid;
		}
		public function set isValid(value:Boolean):void
		{
			if(_isValid != value)
			{
				_isValid = value;
				if(submitButton)
					submitButton.enabled = isValid;
			}
		}
		
		private var _submitButtonLabel:String;
		public function get submitButtonLabel():String
		{
			return _submitButtonLabel;
		}
		public function set submitButtonLabel(value:String):void
		{
			_submitButtonLabel = value;
		}
		
		protected var submitButton:Button;
		protected var cancelButton:Button;
		
		public function PopupWindowBase()
		{
			super();
			
			addEventListener(FlexEvent.CREATION_COMPLETE, init);
		}

		override protected function createChildren():void
		{
			super.createChildren();

			var cb:ControlBar = controlBar as ControlBar;
			
			if(cb)
			{
				cb.setConstraintValue("horizontalAlign", "center");
				
				if(!submitButton)
				{
					submitButton = new Button();
					submitButton.addEventListener(MouseEvent.CLICK, submit);
					submitButton.label = submitButtonLabel;
					submitButton.enabled = isValid;
					cb.addChild(submitButton);
					defaultButton = submitButton;
				}
				
				if(!cancelButton && showCancelButton)
				{
					cancelButton = new Button();
					cancelButton.addEventListener(MouseEvent.CLICK, cancelHandler);
					cancelButton.label = "cancel";
					cb.addChild(cancelButton);
				}
			}
			setStyle("borderAlpha", 0.8);
			setStyle("borderColor", soundAndColor.backgroundColor);
			setStyle("titleStyleName", "whiteBoldBig");
		}


		protected function init(event:FlexEvent):void
		{
			// override me
		}
		
		protected function submit(event:Event):void
		{
			// override me
		}
		
		public function validateInput(event:Event, message:String="can not be empty", validateFunction:Function=null):void
		{
			var target:UIComponent = event.currentTarget as UIComponent;
			
			if(!target)
				return;
			
			var toolTip:ToolTip = errorMessageToolTips[target.name] as ToolTip;
			
			if((validateFunction != null && !validateFunction.call(target)) ||
				validateFunction == null && 
					(target is TextInput && (target as TextInput).text == "" ||
					target is List && getSelected(target as List).length < 1))
			{
				if (toolTip)
				{
					toolTip.visible = true;
				}
				else
				{
					// Create the ToolTip instance.
					var pt:Point = new Point(target.x, target.y);
					pt = target.contentToGlobal(pt);
					toolTip = ToolTipManager.createToolTip(message, pt.x + target.width, pt.y) as ToolTip;
					toolTip.setStyle("styleName", "errorTip");
					 
					errorMessageToolTips[target.name] = toolTip;
				}
			}
			else if(toolTip)
			{
				toolTip.visible = false;
			}
			
			validateForm();
 		}
 		
		public function getSelected(list:List):Array
		{
			var result:Array = new Array();
			for each(var o:Object in list.dataProvider)
			{
				if(o.selected)
					result.push(o.data);
			}
			return result;
		}
		
		public function wrapArray(array:Array):Array
		{
			var result:Array = new Array();
			for each(var d:Object in array)
			{
				var o:Object = new Object();
				o.selected = false;
				o.data = d;
				if(d is Buddy)
					o.nickname = d.nickname;
				result.push(o);
			}
			return result;
		}
 		
 		public function hideErrors():void
 		{
 			for each(var toolTip:ToolTip in errorMessageToolTips)
				toolTip.visible = false;
 		}
 		
 		protected function validateForm():void
 		{
 			// override me
 		}
 		
 		protected function cancelHandler(event:Event):void
 		{
 			closeWindow();
 		}
 		
 		public function closeWindow():void
 		{
 			for each(var toolTip:ToolTip in errorMessageToolTips)
				ToolTipManager.destroyToolTip(toolTip);

 			dispatchEvent(new CloseEvent(CloseEvent.CLOSE));
 		}
		
		
	}
}