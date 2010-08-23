package com.cleartext.esm.views.messages
{
	import com.cleartext.esm.events.AvatarEvent;
	import com.cleartext.esm.events.LinkEvent;
	import com.cleartext.esm.models.ApplicationModel;
	import com.cleartext.esm.models.AvatarModel;
	import com.cleartext.esm.models.ChatModel;
	import com.cleartext.esm.models.valueObjects.Avatar;
	import com.cleartext.esm.models.valueObjects.IBuddy;
	import com.cleartext.esm.models.valueObjects.Message;
	import com.cleartext.esm.models.valueObjects.UserAccount;
	import com.cleartext.esm.views.common.AvatarRenderer;
	import com.universalsprout.flex.components.list.SproutListRendererBase;
	
	import flash.events.TextEvent;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	
	import mx.core.UITextField;
	import mx.formatters.DateFormatter;
	
	import org.swizframework.Swiz;

	public class MessageRendererBase extends SproutListRendererBase
	{
		[Autowire]
		public var chats:ChatModel;
		
		[Autowire]
		public var appModel:ApplicationModel;
		
		[Autowire]
		public var avatarModel:AvatarModel;
		
		protected var df:DateFormatter;

		protected var avatarRenderer:AvatarRenderer;
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
			super(NaN, NaN);

			df = new DateFormatter();
			df.formatString = "EEE MMM D YYYY at L:NN:SS A";
		}

		public function get message():Message
		{
			return data as Message;
		}
		
		private var _avatar:Avatar;
		public function get avatar():Avatar
		{
			return _avatar;
		}
		public function set avatar(value:Avatar):void
		{
			if(avatar != value)
			{
				if(avatar)
					avatar.removeEventListener(AvatarEvent.MBLOG_VALUES_CHANGE, avatarValuesChangeHandler);
				
				_avatar = value;

				if(avatar)
					avatar.addEventListener(AvatarEvent.MBLOG_VALUES_CHANGE, avatarValuesChangeHandler);

				invalidateProperties();
			}
		}
		
		protected function avatarValuesChangeHandler(event:AvatarEvent):void
		{
			invalidateProperties();
		}
		
		override protected function commitProperties():void
		{
			if(message)
			{
				avatar = avatarModel.getAvatar(message.sender);
				fromThisUser = (avatar == avatarModel.userAccountAvatar);
				if(avatarRenderer)
					avatarRenderer.avatar = avatar;
				
				nameTextField.text = "";//(fromBuddy) ? fromBuddy.nickname : "";
				nameTextField.width = nameTextField.textWidth + padding*4;
				nameTextField.styleName = (fromThisUser) ? "lGreyBold" : "blackBold";

				dateTextField.text = df.format(message.sortDate);
				dateTextField.width = dateTextField.textWidth + padding*2;
				dateTextField.styleName = (fromThisUser) ? "lGreySmall" : "blackSmall";

				if(message.displayMessage)
					bodyTextField.htmlText = message.displayMessage;
				else
					bodyTextField.text = message.plainMessage;

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
				avatarRenderer = new AvatarRenderer();
				avatarRenderer.width = avatarSize;
				avatarRenderer.height = avatarSize;
				addChild(avatarRenderer);
			}
			
			if(!dateTextField)
			{
				dateTextField = new UITextField();
				dateTextField.autoSize = TextFieldAutoSize.NONE;
				dateTextField.ignorePadding = true;
				dateTextField.multiline = false;
				dateTextField.selectable = true;
				dateTextField.type = TextFieldType.DYNAMIC;
				dateTextField.wordWrap = false;
				addChild(dateTextField);
			}

			if(!nameTextField)
			{
				nameTextField = new UITextField();
				nameTextField.autoSize = TextFieldAutoSize.NONE;
				nameTextField.ignorePadding = true;
				nameTextField.multiline = false;
				nameTextField.selectable = true;
				nameTextField.type = TextFieldType.DYNAMIC;
				nameTextField.wordWrap = false;
				addChild(nameTextField);
			}

			if(!bodyTextField)
			{
				bodyTextField = new UITextField();
				bodyTextField.autoSize = TextFieldAutoSize.NONE;
				bodyTextField.ignorePadding = true;
				bodyTextField.multiline = true;
				bodyTextField.selectable = true;
				bodyTextField.type = TextFieldType.DYNAMIC;
				bodyTextField.wordWrap = true;
				bodyTextField.addEventListener(TextEvent.LINK, linkHandler);
				addChild(bodyTextField);
			}
		}
		
		private function linkHandler(event:TextEvent):void
		{
			Swiz.dispatchEvent(new LinkEvent(LinkEvent.LINK_CLICKED, event.text));
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