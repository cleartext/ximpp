package com.cleartext.ximpp.views.buddies
{
	import com.cleartext.ximpp.assets.Constants;
	import com.cleartext.ximpp.events.BuddyRequestEvent;
	import com.cleartext.ximpp.models.BuddyRequestModel;
	import com.cleartext.ximpp.models.XMPPModel;
	import com.cleartext.ximpp.models.types.SubscriptionTypes;
	import com.cleartext.ximpp.models.valueObjects.BuddyRequest;
	import com.universalsprout.flex.components.list.SproutListRendererBase;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	
	import mx.controls.Button;
	import mx.core.UITextField;

	public class BuddyRequestRenderer extends SproutListRendererBase
	{
		[Autowire]
		public var xmpp:XMPPModel;
		
		[Autowire]
		public var requests:BuddyRequestModel;
		
		private static const PADDING:Number = 4;
		private static const BUTTON_SIZE:Number = 16;
		
		//---------------------------------------
		// Constructor
		//---------------------------------------
		
		public function BuddyRequestRenderer(initialWidth:Number=NaN, initialHeight:Number=NaN)
		{
			super(initialWidth, 40);
			heightTo = 40;
		}
		
		private function get request():BuddyRequest
		{
			return data as BuddyRequest;
		}
		
		override public function set data(value:Object):void
		{
			if(request)
				request.removeEventListener(BuddyRequestEvent.BUDDY_REQUEST_CHANGED, buddyRequestChangedHandler);
			
			super.data = value;

			if(request)
				request.addEventListener(BuddyRequestEvent.BUDDY_REQUEST_CHANGED, buddyRequestChangedHandler);
			
			buddyRequestChangedHandler(null);
		}
		
		private function buddyRequestChangedHandler(event:BuddyRequestEvent):void
		{
			invalidateProperties();
			invalidateDisplayList();
		}
		
		//---------------------------------------
		// Display Children
		//---------------------------------------
		
		private var textField:UITextField;
		private var buttons:Array = new Array();
		
		protected var heightInvalid:Boolean = true;
		protected var incoming:Object = null;
		
		override protected function commitProperties():void
		{
			if(request)
			{
				var text:String = "";
				
				if(request.incomming)
				{
					if(request.nickname)
						text += "<b>" + request.nickname + "</b> (" + request.jid + ")";
					else
						text += "<b>" + request.jid + "</b>";
					
					text += " wants to be added to your buddy list.";
					
					if(request.message)
						text += "<br/>They sent you the following message:<br/><br/>" + request.message;
				}
				else
				{
					text += "You added ";

					if(request.nickname)
						text += "<b>" + request.nickname + "</b> (" + request.jid + ")";
					else
						text += "<b>" + request.jid + "</b>";
					
					text += " to your buddy list, but they haven't accepted.";
				}
				
				createButtons(request.incomming);
				
				textField.htmlText = text;
				textField.styleName = "lGreySmall";
			}
			
			heightInvalid = true;
			calculateHeight();
		}
		
		public function createButtons(incoming:Object):void
		{
			if(incoming == null || this.incoming == incoming)
				return;
			
			// remove all existing buttons
			for each(var button:DisplayObject in buttons)
				removeChild(button);
			buttons = new Array();
			
			var objs:Array = (incoming) ?
				[
				{data: "approve", toolTip: "approve", upIcon: Constants.ApproveUp, overIcon: Constants.ApproveOver},
				{data: "deny", toolTip: "deny", upIcon: Constants.DenyUp, overIcon: Constants.DenyOver},
				{data: "ignore", toolTip: "ignore", upIcon: Constants.TrashUp, overIcon: Constants.TrashOver},
				] : [
				{data: "resend", toolTip: "re-send request", upIcon: Constants.ReplyUp, overIcon: Constants.ReplyOver},
				{data: "cancel", toolTip: "cancel", upIcon: Constants.TrashUp, overIcon: Constants.TrashOver}
				];
			
			for each (var obj:Object in objs)
			{
				var btn:Button = new Button();
				btn.data = obj.data;
				btn.addEventListener(MouseEvent.CLICK, button_clickHandler, false, 0, true);
				btn.toolTip = obj.toolTip;
				btn.setStyle("skin", null);
				btn.setStyle("upIcon", obj.upIcon);
				btn.setStyle("overIcon", obj.overIcon);
				btn.setStyle("downIcon", obj.upIcon);
				btn.width = BUTTON_SIZE;
				btn.height = BUTTON_SIZE;
				btn.buttonMode = true;
				buttons.push(btn);
				addChild(btn);
			}
		}

		private function button_clickHandler(event:MouseEvent):void
		{
			switch(event.target.data)
			{
				case "approve" :
					if(xmpp.connected)
						xmpp.addToRoster(request.jid, request.nickname, null);
					break;
				case "deny" :
					if(xmpp.connected)
					{
						xmpp.sendSubscribe(request.jid, SubscriptionTypes.UNSUBSCRIBED);
						requests.removeRequest(request);
					}
					break;
				case "ignore" :
					requests.removeRequest(request);
					break;
				case "block" :
					// todo
					break;
				case "resend" :
					if(xmpp.connected)
						xmpp.sendSubscribe(request.jid, SubscriptionTypes.SUBSCRIBE);
					break;
				case "cancel" :
					requests.removeRequest(request);
					break;
			}
		}

		protected function get textFieldWidth():Number
		{
			return width - 2*PADDING - BUTTON_SIZE ;
		}
		
		protected function calculateHeight():Number
		{
			var newHeight:Number = UITEXTFIELD_HEIGHT_PADDING;

			if(!heightInvalid)
			{
				newHeight = (textField) ? textField.height : newHeight;
			}
			else
			{
				heightInvalid = false;
				
				if(textField)
				{
					textField.wordWrap = true;
					textField.width = textFieldWidth;
					
					for(var l:int=textField.numLines-1; l>=0; l--)
						newHeight += Math.ceil(textField.getLineMetrics(l).height);
		
					textField.height = newHeight;
				}
			}
			newHeight = Math.max(newHeight, buttons.length*(PADDING + BUTTON_SIZE)-PADDING) + 2*PADDING;
			heightTo = newHeight;
			return heightTo;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();

			if(!textField)
			{
				textField = new UITextField();
				textField.autoSize = TextFieldAutoSize.NONE;
				textField.ignorePadding = true;
				textField.multiline = true;
				textField.selectable = true;
				textField.type = TextFieldType.DYNAMIC;
				textField.wordWrap = true;
				textField.y = PADDING;
				textField.x = PADDING;
				addChild(textField);
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
		
		//---------------------------------------
		// Update Display List
		//---------------------------------------
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var yCounter:Number = PADDING;
			var xCounter:Number = unscaledWidth - PADDING - BUTTON_SIZE;

			for(var row:int=0; row<buttons.length; row++)
			{
				var btn:Button = buttons[row] as Button;
				btn.move(xCounter, yCounter);
				yCounter += PADDING + BUTTON_SIZE;
			}
			
			var g:Graphics = graphics;
			g.clear();

			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(unscaledWidth, unscaledHeight, Math.PI/2);
			
			g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xdedede], [0.5, 0.5], [95, 255], matrix);
			g.drawRect(0, 0, unscaledWidth, unscaledHeight);
			
			g.beginFill(0x000000, 0.15)
			g.drawRect(0, unscaledHeight-1, unscaledWidth, 1);
		}
	}		
}