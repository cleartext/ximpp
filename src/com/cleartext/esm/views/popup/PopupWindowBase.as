package com.cleartext.esm.views.popup
{
	import com.cleartext.esm.models.SoundAndColorModel;
	import com.cleartext.esm.models.valueObjects.Buddy;
	import com.cleartext.esm.models.valueObjects.BuddyGroup;
	import com.cleartext.esm.models.valueObjects.IBuddy;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.controls.TextInput;
	import mx.controls.ToolTip;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.FocusManager;
	import mx.managers.ToolTipManager;
	
	import spark.components.Button;
	import spark.components.Group;
	import spark.components.List;
	import spark.components.TitleWindow;

	public class PopupWindowBase extends TitleWindow
	{
		[Autowire]
		public var soundAndColor:SoundAndColorModel;

		public var showCancelButton:Boolean = true;

		public var closing:Boolean = false;
		
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
			
			addEventListener(FlexEvent.CONTENT_CREATION_COMPLETE, init);
			addEventListener(KeyboardEvent.KEY_DOWN, myKeyDownHandler);
			addEventListener(CloseEvent.CLOSE, closeWindow);
		}
		
		protected function myKeyDownHandler(event:KeyboardEvent):void
		{
			if(event.keyCode == Keyboard.ENTER && isValid)
				submit(null);
		}
		
		protected function init(event:Event):void
		{
			//override me
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!submitButton)
			{
				submitButton = new Button();
				submitButton.addEventListener(MouseEvent.CLICK, submit);
				submitButton.label = submitButtonLabel;
				submitButton.enabled = isValid;
				defaultButton = submitButton;
				controlBarContent.push(submitButton);
			}
			
			if(!cancelButton && showCancelButton)
			{
				cancelButton = new Button();
				cancelButton.addEventListener(MouseEvent.CLICK, cancelHandler);
				cancelButton.label = "Cancel";
				cancelButton.focusEnabled = false;
				controlBarContent.push(cancelButton);
			}
		}
				
		protected function submit(event:Event):void
		{
			// override me
		}
		
		public function validateInput(event:Event, message:String="can not be empty", validateFunction:Function=null):void
		{
			var target:UIComponent = event.currentTarget as UIComponent;
			
			if(!target)
			{
				validateForm();
				return;
			}
			
			var toolTip:ToolTip = errorMessageToolTips[target.name] as ToolTip;
			
			if((validateFunction != null && !validateFunction.call(target)) ||
				validateFunction == null && 
					(target is TextInput && (target as TextInput).text == "" ||
					target is List && getSelected(target as List).length < 1))
			{
				if(!toolTip)
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
				ToolTipManager.destroyToolTip(toolTip);
				delete errorMessageToolTips[target.name];
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
		
		public function wrapArray(array:Array):ArrayCollection
		{
			var result:ArrayCollection = new ArrayCollection();
			for each(var d:Object in array)
			{
				var o:Object = new Object();
				o.selected = false;
				o.data = d;
				result.addItem(o);
			}
			return result;
		}
 		
 		public function hideErrors():void
 		{
			setFocus();
			for each(var toolTip:ToolTip in errorMessageToolTips)
			{
				ToolTipManager.destroyToolTip(toolTip);
			}
			errorMessageToolTips = new Dictionary();
 		}
 		
 		protected function validateForm():void
 		{
 			// override me
 		}
 		
 		protected function cancelHandler(event:Event):void
 		{
 			closeWindow();
 		}
 		
 		public function closeWindow(event:Event=null):void
 		{
			hideErrors();

			closing = true;
			if(!event)
 				dispatchEvent(new CloseEvent(CloseEvent.CLOSE));
 		}
	}
}