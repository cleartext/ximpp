package com.cleartext.esm.views.common
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	
	import mx.controls.ComboBox;
	import mx.events.FlexEvent;

	public class UpComboBox extends ComboBox
	{
		public function UpComboBox()
		{
			super();
		}

		override public function open():void
		{
			displayDropdown(true);
		}
		
		override public function close(trigger:Event = null):void
		{
			if (showingDropdown)
			{
				if (_dropdown && selectedIndex != _dropdown.selectedIndex)
					selectedIndex = _dropdown.selectedIndex;
				
				displayDropdown(false, trigger);
				
				dispatchChangeEvent(new Event("dummy"), _selectedIndexOnDropdown, selectedIndex);
			}
		}
		
		protected function displayDropdown(show:Boolean, trigger:Event = null):void
		{
			
		}

		override protected function downArrowButton_buttonDownHandler(event:FlexEvent):void
		{
			// The down arrow should always toggle the visibility of the dropdown.
			if (_showingDropdown)
				close(event);
			else
				displayDropdown(true, event);
		}

		override protected function keyDownHandler(event:KeyboardEvent):void
		{
			// If the combo box is disabled, don't do anything
			if(!enabled)
				return;
			
			// If a the editable field currently has focus, it is handling
			// all arrow keys. We shouldn't also scroll this selection.
			if (event.target == textInput)
				return;
			
			if (event.ctrlKey && event.keyCode == Keyboard.DOWN)
			{
				displayDropdown(true, event);
				event.stopPropagation();
			}
			else if (event.ctrlKey && event.keyCode == Keyboard.UP)
			{
				close(event);
				event.stopPropagation();
			}
			else if (event.keyCode == Keyboard.ESCAPE)
			{
				if (_showingDropdown)
				{
					if (_oldIndex != _dropdown.selectedIndex)
						selectedIndex = _oldIndex;
					
					displayDropdown(false);
					event.stopPropagation();
				}
			}
			
			else if (event.keyCode == Keyboard.ENTER)
			{
				if (_showingDropdown)
				{
					close();
					event.stopPropagation();
				}
			}
			else
			{
				if (!editable ||
					event.keyCode == Keyboard.UP ||
					event.keyCode == Keyboard.DOWN ||
					event.keyCode == Keyboard.PAGE_UP ||
					event.keyCode == Keyboard.PAGE_DOWN)
				{
					var oldIndex:int = selectedIndex;
					
					// Make sure we know we are handling a keyDown,
					// so if the dropdown sends out a "change" event
					// (like when an up-arrow or down-arrow changes
					// the selection) we know not to close the dropdown.
					bInKeyDown = _showingDropdown;
					// Redispatch the event to the dropdown
					// and let its keyDownHandler() handle it.
					
					dropdown.dispatchEvent(event.clone());
					event.stopPropagation();
					bInKeyDown = false;
					
				}
			}
		}
	}
}