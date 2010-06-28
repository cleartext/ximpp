package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.events.HasAvatarEvent;
	import com.cleartext.ximpp.models.valueObjects.IHasJid;
	import com.cleartext.ximpp.models.valueObjects.IHasStatus;
	import com.cleartext.ximpp.views.common.StatusIcon;
	import com.universalsprout.flex.components.list.IDisposable;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	
	import mx.controls.listClasses.IListItemRenderer;
	import mx.core.IDataRenderer;
	import mx.core.IUIComponent;
	import mx.core.UIComponent;
	import mx.core.UITextField;

	public class ChatRoomParticipantRenderer extends UIComponent implements IDataRenderer, IUIComponent, IDisposable, IListItemRenderer
	{
		private static const PADDING:Number = 3;
		
		private var statusIcon:StatusIcon;
		private var nameLabel:UITextField;
		
		private function get participant():IHasStatus
		{
			return _data as IHasStatus;
		}

		public function ChatRoomParticipantRenderer()
		{
			super();
			height = 30;
			percentWidth = 100;
		}
		
		private var _data:Object;
		public function get data():Object
		{
			return _data;
		}
		public function set data(value:Object):void
		{
			if(data == value)
				return;

			if(participant)
				participant.removeEventListener(HasAvatarEvent.CHANGE_SAVE, participantChangedHandler);
			
			_data = value;

			if(participant)
			{
				participant.addEventListener(HasAvatarEvent.CHANGE_SAVE, participantChangedHandler);
			}
			
			participantChangedHandler(null);
		}
		
		private function participantChangedHandler(event:HasAvatarEvent):void
		{
			invalidateProperties();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!statusIcon)
			{
				statusIcon = new StatusIcon();
				statusIcon.width = StatusIcon.SIZE;
				statusIcon.height = StatusIcon.SIZE;
				statusIcon.y = 5;
				statusIcon.x = 8;
				addChild(statusIcon);
			}

			if(!nameLabel)
			{
				nameLabel = new UITextField();
				nameLabel.styleName = "dGreyBold";
				nameLabel.x = 30;
				nameLabel.y = 5;
				addChild(nameLabel);
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();

			if(!participant)
				return;
	
			// set values
			nameLabel.text = (participant as IHasJid).nickname;
			statusIcon.status.value = participant.status.value;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			nameLabel.width = unscaledWidth - 40;
			
			var g:Graphics = graphics;
			g.clear();

			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(unscaledWidth, unscaledHeight, Math.PI/2);
			g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xdedede], [0.5, 0.5], [95, 255], matrix);
			g.drawRect(0, 0, unscaledWidth, unscaledHeight);
		}

		public function dispose():void
		{
			if(participant)
				participant.removeEventListener(HasAvatarEvent.CHANGE_DISPLAY, participantChangedHandler);
		}
	}
}