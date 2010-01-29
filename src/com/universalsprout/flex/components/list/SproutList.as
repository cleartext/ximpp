package com.universalsprout.flex.components.list
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	import mx.collections.XMLListCollection;
	import mx.core.Container;
	import mx.core.IFactory;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.ResizeEvent;
	
	[Event(name="collectionChange", type="mx.events.CollectionEvent")]
	[Event(name="itemDoubleClicked", type="com.universalsprout.flex.components.list.SproutListEvent")]
	
	public class SproutList extends Container
	{
		public function SproutList()
		{
			super();
			setStyle("verticalGap", 0);
			verticalScrollPolicy = ScrollPolicy.ON;
		}
		
		public var animate:Boolean = true;
		
		public var bottomUp:Boolean = false;
		
		protected var collection:ListCollectionView;
	
		protected var list:IList;
		
		protected var itemRenderersByDataUid:Dictionary = new Dictionary();
	
		protected var itemHeightsInvalid:Boolean = false;
		
		protected var resetItemRenderers:Boolean = false;
		
		// used to keep scroll at base if bottomUp==true
		protected var previousHeight:Number = 0;
		
		protected var previousItemWidth:Number = 0;
		
		protected var highlightChanged:Boolean = false;
		
		private var _itemRenderer:IFactory;
		public function get itemRenderer():IFactory
		{
			return _itemRenderer;
		}
		public function set itemRenderer(value:IFactory):void
		{
			trace(getTimer(), "set itemRenderer()");
	
			_itemRenderer = value;
			resetItemRenderers = true;
			invalidateSize();
			invalidateDisplayList();
			dispatchEvent(new Event("itemRendererChanged"));
		}
		
		//----------------------------------
		//  dataProvider
		//----------------------------------
		
		[Bindable("collectionChange")]
		[Inspectable(category="Data", defaultValue="undefined")]
		public function get dataProvider():ListCollectionView
		{
			return collection;
		}
		public function set dataProvider(value:ListCollectionView):void
		{
			if (collection)
			{
				collection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
				collection.removeEventListener("listChanged", listChangedHandler);
			}
	
			if (value is Array)
			{
				collection = new ArrayCollection(value as Array);
			}
			else if (value is IList)
			{
				collection = new ListCollectionView(IList(value));
			}
			else if (value is XMLList)
			{
				collection = new XMLListCollection(value as XMLList);
			}
			else if (value is Dictionary)
			{
				var colTemp:ArrayCollection = new ArrayCollection();
				for each(var item:Object in Dictionary)
					colTemp.addItem(item);
				collection = colTemp;
			}
			else if (value is XML)
			{
				var xl:XMLList = new XMLList();
				xl += value;
				collection = new XMLListCollection(xl);
			}
			else
			{
				// convert it to an array containing this one item
				var tmp:Array = [];
				if (value != null)
					tmp.push(value);
				collection = new ArrayCollection(tmp);
			}
	
			collection.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler, false, 0, true);
			collection.addEventListener("listChanged", listChangedHandler, false, 0, true);
			listChangedHandler(null);
	
			resetItemRenderers = true;
			invalidateProperties();
		}
		
		override public function set doubleClickEnabled(value:Boolean):void
		{
			super.doubleClickEnabled = value;
			
			for each(var item:UIComponent in itemRenderersByDataUid)
			{
				if(doubleClickEnabled)
					item.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler, false, 0, true);
				else
					item.removeEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler);
			}
		}
		
		protected function listChangedHandler(event:Event):void
		{
			if(list)
				list.removeEventListener(CollectionEvent.COLLECTION_CHANGE, listCollectionChangeHandler);
			
			list = collection.list;
			
			if(list)
				list.addEventListener(CollectionEvent.COLLECTION_CHANGE, listCollectionChangeHandler, false, 0, true);
		}
	
	   /**
		 *  Handles CollectionEvents dispatched from the data provider
		 *  as the data changes.
		 *  Updates the renderers, selected indices and scrollbars as needed.
		 *
		 *  @param event The CollectionEvent.
		 */
		protected function collectionChangeHandler(event:CollectionEvent):void
		{
			switch(event.kind)
			{
				case CollectionEventKind.MOVE :
					break;
	
				case CollectionEventKind.REFRESH :
					break;
	
				case CollectionEventKind.RESET :
					resetItemRenderers = true;
					invalidateProperties();
					break;
	
				case CollectionEventKind.ADD :
				case CollectionEventKind.REMOVE :
				case CollectionEventKind.REPLACE :
				case CollectionEventKind.UPDATE :
					// do nothing
					break;
	
				default :
					trace("[SproutList] collectionChangeHander() called with unknown kind: " + event.kind);
			}
		}
		
		protected function listCollectionChangeHandler(event:CollectionEvent):void
		{
			switch(event.kind)
			{
				case CollectionEventKind.ADD :
					var startIndex:int = event.location;
					for each(var add:ISproutListData in event.items)
						createItemRenderer(add, startIndex++);
					break;
	
				case CollectionEventKind.REMOVE :
					for each(var remove:ISproutListData in event.items)
						removeItemRenderer(itemRenderersByDataUid[remove.uid]);
					break;
	
				case CollectionEventKind.REPLACE :
					// replace the item
					break;
	
				case CollectionEventKind.RESET :
				case CollectionEventKind.REFRESH :
				case CollectionEventKind.MOVE :
				case CollectionEventKind.UPDATE :
					// do nothing
					break;
	
				default :
					trace("[SproutList] collectionChangeHander() called with unknown kind: " + event.kind);
			}
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(resetItemRenderers)
			{
				resetItemRenderers = false;
				for each(var item:DisplayObject in itemRenderersByDataUid)
					removeItemRenderer(item);
				
				for each(var data:ISproutListData in dataProvider.list)
					createItemRenderer(data);
			}
			
			if(itemHeightsInvalid)
			{
				itemHeightsInvalid = false;
				
				
			}
		}
		
		private function createItemRenderer(data:ISproutListData, index:int=-1):void
		{
			var item:UIComponent = itemRenderer.newInstance();
			(item as ISproutListItem).data = data;
			item.addEventListener(ResizeEvent.RESIZE, itemsResizeHandler, false, 0, true);
			itemRenderersByDataUid[data.uid] = item;
			if(index==-1)
				index = numChildren;
			addChildAt(item, index);
	
			if(doubleClickEnabled)
				item.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler, false, 0, true);
		}
		
		private function removeItemRenderer(item:DisplayObject):void
		{
			delete itemRenderersByDataUid[(item as ISproutListItem).data.uid];
			
			item.removeEventListener(ResizeEvent.RESIZE, itemsResizeHandler);
			if(doubleClickEnabled)
				item.removeEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler);
			removeChild(item);
		}
		
		private function itemsResizeHandler(event:ResizeEvent):void
		{
			itemHeightsInvalid = true;
			invalidateProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
	
			var yCounter:Number = 0;
			var vGap:Number = getStyle("verticalGap");
			
			var itemWidth:Number = unscaledWidth - viewMetricsAndPadding.left - viewMetricsAndPadding.right;
			if(itemWidth == previousItemWidth)
			{
//				return;
			}
			
			previousItemWidth = itemWidth;
			
			var highlightFlag:Boolean = false;
			
			var index:int = 0;
			for each(var data:ISproutListData in collection)
			{
				// find a itemRenderer if one exists
				var item:UIComponent = itemRenderersByDataUid[data.uid];
				
				if(!item)
				{
				}
				
				// layout itemRenderer
				var customItem:ISproutListItem = item as ISproutListItem;
				if(customItem)
				{
					customItem.highlight = highlightFlag;
					highlightFlag = !highlightFlag;
					if(animate)
						customItem.tweenTo(0, yCounter);
					else
						item.move(0,yCounter);
	
					yCounter += vGap + customItem.heightTo;
	
					item.setActualSize(itemWidth, item.height);
					setChildIndex(item, index);
					index++;
				}
			}
			
			if(yCounter != previousHeight)
			{
				if(bottomUp)
					verticalScrollPosition += yCounter-previousHeight;
				previousHeight = yCounter;
			}
			
			var end:int = getTimer();
			//trace(end + " : " + (end - start) + " " + this + " creatingRows");
		}
		
		protected function doubleClickHandler(event:MouseEvent):void
		{
			var item:ISproutListItem = event.currentTarget as ISproutListItem;
			if(item)
				dispatchEvent(new SproutListEvent(SproutListEvent.ITEM_DOUBLE_CLICKED, item.data as ISproutListData));
		}
	}
}