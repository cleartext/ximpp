package com.universalsprout.flex.components.list
{
	import com.adobe.air.filesystem.VolumeMonitor;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	import mx.collections.XMLListCollection;
	import mx.core.Container;
	import mx.core.IFactory;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.ResizeEvent;
	
	[Event(name="collectionChange", type="mx.events.CollectionEvent")]
	
	public class SproutList extends Container
	{
		public function SproutList()
		{
			super();
			setStyle("verticalGap", 0);
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
		
		protected var previousWidth:Number = 0;
		
		protected var highlightChanged:Boolean = false;
		
		private var _itemRenderer:IFactory;
		public function get itemRenderer():IFactory
		{
			return _itemRenderer;
		}
		public function set itemRenderer(value:IFactory):void
		{
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
			//trace("collection", event.kind);
			switch(event.kind)
			{
				case CollectionEventKind.UPDATE :
				case CollectionEventKind.MOVE :
				case CollectionEventKind.REFRESH :
					itemHeightsInvalid = true;
					invalidateProperties();
					break;
	
				case CollectionEventKind.RESET :
					resetItemRenderers = true;
					invalidateProperties();
					break;
	
				case CollectionEventKind.ADD :
				case CollectionEventKind.REMOVE :
				case CollectionEventKind.REPLACE :
					// do nothing
					break;
	
				default :
					trace("[SproutList] collectionChangeHander() called with unknown kind: " + event.kind);
			}
			invalidateDisplayList();
		}
		
		protected function listCollectionChangeHandler(event:CollectionEvent):void
		{
			//trace("list      ", event.kind);
			switch(event.kind)
			{
				case CollectionEventKind.ADD :
					var startIndex:int = event.location;
					for each(var add:ISproutListData in event.items)
						createItemRenderer(add);
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
			invalidateDisplayList();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			var item:ISproutListItem;
			var data:ISproutListData;

			if(resetItemRenderers)
			{
				resetItemRenderers = false;
				for each(item in itemRenderersByDataUid)
					removeItemRenderer(item as DisplayObject);
				
				for each(data in dataProvider.list)
					createItemRenderer(data);

				itemHeightsInvalid = true;
			}
			
			if(itemHeightsInvalid)
			{
				itemHeightsInvalid = false;
				
				var yCounter:Number = 0;
				var vGap:Number = getStyle("verticalGap");
				var itemWidth:Number = unscaledWidth - viewMetricsAndPadding.left - viewMetricsAndPadding.right;
				if(verticalScrollBar)
					itemWidth -= verticalScrollBar.width;
				var uid:String;
				
				// set them all to invisible first, then later, make them
				// visible if we want them
				for each(item in getChildren())
				{
					item.setVisible(false, true);
					item.setIncludeInLayout(false, true);
				}
				
				for each(data in collection)
				{
					// find itemRenderer
					item = createItemRenderer(data);
					item.setVisible(true, true);
					item.setIncludeInLayout(true, true);

					if(animate)
						item.yTo = yCounter;
					else
						item.move(0, yCounter);
	
					yCounter += vGap + item.setWidth(itemWidth);
				}
				
				if(yCounter != previousHeight)
				{
					if(bottomUp)
						verticalScrollPosition += yCounter-previousHeight;
					previousHeight = yCounter;
				}
			}
		}
		
		private function createItemRenderer(data:ISproutListData):ISproutListItem
		{
			var item:ISproutListItem = itemRenderersByDataUid[data.uid]; 
			if(!item)
			{
				item = itemRenderer.newInstance();
				item.data = data;
				item.addEventListener(ResizeEvent.RESIZE, itemsResizeHandler, false, 0, true);
				itemRenderersByDataUid[data.uid] = item;
				addChild(item as UIComponent);
			}
			return item;
		}
		
		private function removeItemRenderer(item:DisplayObject):void
		{
			delete itemRenderersByDataUid[(item as ISproutListItem).data.uid];
			item.removeEventListener(ResizeEvent.RESIZE, itemsResizeHandler);
			removeChild(item);
		}
		
		private function itemsResizeHandler(event:ResizeEvent):void
		{
			callLater(invalidateLater);
		}
		
		protected function invalidateLater():void
		{
			itemHeightsInvalid = true;
			invalidateProperties();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			for each(var child:DisplayObject in getChildren())
			{
				if(child.width != unscaledWidth)
				{
					itemHeightsInvalid = true;
					invalidateProperties();
					return;
				}
			}
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
	}
}