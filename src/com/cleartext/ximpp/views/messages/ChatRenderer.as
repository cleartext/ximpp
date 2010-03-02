package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.models.BuddyModel;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	import com.cleartext.ximpp.views.common.Avatar;
	import com.universalsprout.flex.components.list.SproutListItemBase;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	
	import mx.core.UITextField;
	import mx.formatters.DateFormatter;
	
	public class ChatRenderer extends SproutListItemBase
	{
		[Autowire]
		public var buddies:BuddyModel;
		
		[Autowire(bean="settings", property="userAccount")]
		public var userAccount:UserAccount;
		
		private static const AVATAR_SIZE:Number = 32;
		private static const PADDING:Number = 5;
		private static const TOP_ROW_HEIGHT:Number = 28;
		
		private var df:DateFormatter;
		
		private var _showTopRow:Boolean = true;
		public function get showTopRow():Boolean
		{
			return _showTopRow;
		}
		public function set showTopRow(value:Boolean):void
		{
			if(_showTopRow != value)
			{
				_showTopRow = value;
				invalidateProperties();
			}
		}
		
		public function ChatRenderer()
		{
			super();
			
			df = new DateFormatter();
			df.formatString = "EEE MMM D YYYY at L:NN A";
		}

		private var avatar:Avatar;
		private var nameTextField:UITextField;
		private var dateTextField:UITextField;
		private var bodyTextField:UITextField;

		private var previousWidth:Number;
		private var previousHeight:Number;
		private var dataChanged:Boolean = false;
		
		private var fromThisUser:Boolean = false;
		
		public function get message():Message
		{
			return data as Message;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(message)
			{
				var fromBuddy:Buddy = buddies.getBuddyByJid(message.sender);
				fromThisUser = (fromBuddy == userAccount);
				
				avatar.data = fromBuddy;

				nameTextField.text = fromBuddy.nickName;
				nameTextField.width = nameTextField.textWidth + PADDING;
				nameTextField.styleName = (fromThisUser) ? "lGreyBold" : "blackBold";

				dateTextField.text = df.format(message.timestamp);
				dateTextField.width = dateTextField.textWidth + PADDING;
				dateTextField.styleName = (fromThisUser) ? "lGreySmall" : "blackSmall";

				bodyTextField.text = message.body;
				bodyTextField.styleName = (fromThisUser) ? "lGreyNormal" : "blackNormal";
			}
						
			avatar.visible = showTopRow;
			dateTextField.visible = showTopRow;
			nameTextField.visible = showTopRow;
			
			avatar.includeInLayout = showTopRow;
			dateTextField.includeInLayout = showTopRow;
			nameTextField.includeInLayout = showTopRow;
			
			bodyTextField.y = showTopRow ? TOP_ROW_HEIGHT+PADDING : PADDING;
			dateTextField.x = width - dateTextField.width - 2*PADDING;	

			calculateHeight();
		}
		
		private function calculateHeight():void
		{
			if(!dataChanged && previousWidth == width)
				return;

			dataChanged = false;

			bodyTextField.wordWrap = true;
			bodyTextField.width = width - 8*PADDING - AVATAR_SIZE;
			
			var newHeight:Number = UITEXTFIELD_HEIGHT_PADDING;
			for(var l:int=bodyTextField.numLines-1; l>=0; l--)
				newHeight += Math.ceil(bodyTextField.getLineMetrics(l).height);

			bodyTextField.height = newHeight;
			heightTo = newHeight + ((showTopRow) ? TOP_ROW_HEIGHT+PADDING : PADDING);
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!avatar)
			{
				avatar = new Avatar();
				avatar.width = AVATAR_SIZE;
				avatar.height = AVATAR_SIZE;
				avatar.x = 2*PADDING;
				avatar.y = 2;
				addChild(avatar);
			}
			
			if(!nameTextField)
			{
				nameTextField = new UITextField();
				nameTextField.y = PADDING + 2;
				nameTextField.x = AVATAR_SIZE + 5*PADDING;
				addChild(nameTextField);
			}

			if(!dateTextField)
			{
				dateTextField = new UITextField();
				dateTextField.y = PADDING + 2;
				addChild(dateTextField);
			}

			if(!bodyTextField)
			{
				bodyTextField = new UITextField();
				bodyTextField.x = AVATAR_SIZE + 5*PADDING;
				bodyTextField.selectable = true;
				addChild(bodyTextField);
			}
		}
		
		override public function setWidth(widthVal:Number):Number
		{
			width = widthVal;
			calculateHeight();
			return heightTo;
		}
		
		override public function set heightTo(value:Number):void
		{
			super.heightTo = value;
			updateHeight(value);
		}
		
		override public function set data(value:Object):void
		{
			if(data != value)
			{
				super.data = value;
				dataChanged = true;
				invalidateProperties();
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var g:Graphics = graphics;
			g.clear();

			if(showTopRow)
			{
				var matrix:Matrix = new Matrix();
				matrix.createGradientBox(width, TOP_ROW_HEIGHT, Math.PI/2);
	
				if(fromThisUser)
					g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xdedede], [0.5, 0.5], [95, 255], matrix);
				else
					g.beginGradientFill(GradientType.LINEAR, [0xeeeeee, 0xbbbbbb], [0.5, 0.5], [95, 255], matrix);

				g.drawRoundRect(4*PADDING + AVATAR_SIZE, 2, width-5*PADDING-AVATAR_SIZE, TOP_ROW_HEIGHT-4, 10, 10);
			}
			else
			{
				g.lineStyle(1, 0xdedede);
				
				var xVal:Number = 6*PADDING + AVATAR_SIZE;
				var dash:Number = 3;
				var gap:Number = 3;
				var limit:Number = xVal + 60;
				
				while(xVal < limit)
				{
					g.moveTo(xVal, 0);
					xVal += dash;
					g.lineTo(xVal, 0);
					xVal += gap;
				}
			}
		}
	}
}