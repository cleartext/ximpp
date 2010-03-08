package com.cleartext.ximpp.views.popup
{
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
				if(sumbitButton)
					sumbitButton.enabled = isValid;
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
		
		private var sumbitButton:Button;
		private var cancelButton:Button;
		
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
				
				if(!sumbitButton)
				{
					sumbitButton = new Button();
					sumbitButton.addEventListener(MouseEvent.CLICK, submit);
					sumbitButton.label = submitButtonLabel;
					sumbitButton.enabled = isValid;
					cb.addChild(sumbitButton);
				}
				
				if(!cancelButton)
				{
					cancelButton = new Button();
					cancelButton.addEventListener(MouseEvent.CLICK, closeWindow);
					cancelButton.label = "cancel";
					cb.addChild(cancelButton);
				}
			}
		}


		protected function init(event:FlexEvent):void
		{
			// override me
		}
		
		protected function submit(event:Event):void
		{
			// override me
		}
		
		protected function validateInput(event:Event, message:String="cannot be empty"):void
		{
			var target:UIComponent = event.currentTarget as UIComponent;
			
			if(!target)
				return;
			
			var toolTip:ToolTip = errorMessageToolTips[target.name] as ToolTip;
			
			if(target is TextInput && (target as TextInput).text == "" ||
				target is List && (target as List).selectedItems.length < 1)
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
 		
 		public function hideErrors():void
 		{
 			for each(var toolTip:ToolTip in errorMessageToolTips)
				toolTip.visible = false;
 		}
 		
 		protected function validateForm():void
 		{
 			// override me
 		}
 		
 		public function closeWindow(event:Event=null):void
 		{
 			for each(var toolTip:ToolTip in errorMessageToolTips)
				ToolTipManager.destroyToolTip(toolTip);

 			dispatchEvent(new CloseEvent(CloseEvent.CLOSE));
 		}
		
		
	}
}