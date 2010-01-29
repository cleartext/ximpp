package com.cleartext.ximpp.tests.mesageRenderers
{
	import com.cleartext.ximpp.models.valueObjects.Message;
	
	public class SimpleMessageRenderer extends SproutListItemBase1
	{
		public function SimpleMessageRenderer()
		{
			super();
		}
		
		override public function set data(value:Object):void
		{
			super.data = value;
			
			var m:Message = data as Message;
			if(m && textField)
				textField.text = m.body;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			var m:Message = data as Message;
			
			if(m && textField)
				textField.text = m.body;
		}
		
		override protected function measure():void
		{
			measuredWidth = 300;
			measuredHeight = 100;
			
			textField.width = 300;
			textField.percentHeight = 100;
		}
		
	}
}