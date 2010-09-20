package com.cleartext.esm.events
{
	import com.cleartext.esm.models.valueObjects.FormObject;
	
	import flash.events.Event;

	public class FormEvent extends Event
	{
		public static const NEW_FORM:String = "newForm";
		
		public var form:FormObject;

		public function FormEvent(type:String, form:FormObject, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.form = form;
		}
		
		override public function clone():Event
		{
			return new FormEvent(type, form, bubbles, cancelable);
		}
		
	}
}