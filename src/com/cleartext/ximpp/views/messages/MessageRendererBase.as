package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.models.ApplicationModel;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	import com.cleartext.ximpp.views.common.Avatar;
	import com.universalsprout.flex.components.list.SproutListItemBase;
	
	import flash.utils.getTimer;
	
	import mx.core.UITextField;
	import mx.formatters.DateFormatter;

	public class MessageRendererBase extends SproutListItemBase
	{
		[Autowire]
		public var appModel:ApplicationModel;
		
		[Autowire(bean="settings", property="userAccount")]
		public var userAccount:UserAccount;
		
		private var df:DateFormatter;

		protected var avatar:Avatar;
		protected var nameTextField:UITextField;
		protected var dateTextField:UITextField;
		protected var bodyTextField:UITextField;
		
		protected var heightInvalid:Boolean = true;
		
		protected var fromThisUser:Boolean = false;
		
		protected var avatarSize:Number = 32;
		protected var topRowHeight:Number = 28;
		protected var padding:Number = 5
		
		public function MessageRendererBase()
		{
			super(NaN, 32);

			df = new DateFormatter();
			df.formatString = "EEE MMM D YYYY at L:NN A";
		}

		public function get message():Message
		{
			return data as Message;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(message)
			{
				var fromBuddy:Buddy = appModel.getBuddyByJid(message.sender);
				fromThisUser = (fromBuddy == userAccount);
				
				avatar.data = fromBuddy;

				nameTextField.text = (fromBuddy) ? fromBuddy.nickName : "";
				nameTextField.width = nameTextField.textWidth + padding*4;
				nameTextField.styleName = (fromThisUser) ? "lGreyBold" : "blackBold";

				dateTextField.text = df.format(message.timestamp);
				dateTextField.width = dateTextField.textWidth + padding*2;
				dateTextField.styleName = (fromThisUser) ? "lGreySmall" : "blackSmall";

				bodyTextField.text = message.body;
				bodyTextField.styleName = (fromThisUser) ? "lGreyNormal" : "blackNormal";
			}
					
			heightInvalid = true;
			calculateHeight();
		}
		
		protected function get bodyTextWidth():Number
		{
			return width - 8*padding - avatarSize;
		}
		
		protected function calculateHeight():Number
		{
			var newHeight:Number = UITEXTFIELD_HEIGHT_PADDING;

			if(!heightInvalid)
				return (bodyTextField) ? bodyTextField.height : newHeight;

			heightInvalid = false;
			
			if(bodyTextField)
			{
				bodyTextField.wordWrap = true;
				bodyTextField.width = bodyTextWidth;
				
				for(var l:int=bodyTextField.numLines-1; l>=0; l--)
					newHeight += Math.ceil(bodyTextField.getLineMetrics(l).height);
	
				bodyTextField.height = newHeight;
			}
			
			return newHeight;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!avatar)
			{
				avatar = new Avatar();
				avatar.width = avatarSize;
				avatar.height = avatarSize;
				addChild(avatar);
			}
			
			if(!nameTextField)
			{
				nameTextField = new UITextField();
				addChild(nameTextField);
			}

			if(!dateTextField)
			{
				dateTextField = new UITextField();
				addChild(dateTextField);
			}

			if(!bodyTextField)
			{
				bodyTextField = new UITextField();
				bodyTextField.selectable = true;
				addChild(bodyTextField);
			}
		}
		
		override public function setWidth(widthVal:Number):Number
		{
			if(width != widthVal)
			{
				width = widthVal;
				heightInvalid = true;
			}
			return calculateHeight();
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
				heightInvalid = true;
				invalidateProperties();
			}
		}
	}
}