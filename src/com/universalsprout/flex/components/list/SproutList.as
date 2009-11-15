package com.universalsprout.flex.components.list
{
import flash.events.Event;
import flash.system.System;
import flash.utils.Dictionary;
import flash.utils.getTimer;

import mx.collections.ArrayCollection;
import mx.collections.ICollectionView;
import mx.collections.IList;
import mx.collections.ListCollectionView;
import mx.collections.XMLListCollection;
import mx.core.Container;
import mx.core.IFactory;
import mx.core.ScrollPolicy;
import mx.core.UIComponent;
import mx.events.CollectionEvent;
import mx.events.ResizeEvent;

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
	
	protected var collection:ICollectionView;
	
	protected var itemRenderersByDataUid:Dictionary;
	
	protected var resetItemRenderers:Boolean = false;
	
	protected var bottomPadding:UIComponent;
	
	protected var previousHeight:Number = 0;
	
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
	public function get dataProvider():Object
	{
		return collection;
	}
	public function set dataProvider(value:Object):void
	{
		if (collection)
		{
			collection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
		}

		if (value is Array)
		{
			collection = new ArrayCollection(value as Array);
		}
		else if (value is ICollectionView)
		{
			collection = ICollectionView(value);
		}
		else if (value is IList)
		{
			collection = new ListCollectionView(IList(value));
		}
		else if (value is XMLList)
		{
			collection = new XMLListCollection(value as XMLList);
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

		resetItemRenderers = true;
		invalidateDisplayList();
	}
	
   /**
	 *  Handles CollectionEvents dispatched from the data provider
	 *  as the data changes.
	 *  Updates the renderers, selected indices and scrollbars as needed.
	 *
	 *  @param event The CollectionEvent.
	 */
	protected function collectionChangeHandler(event:Event):void
	{
		invalidateDisplayList();
	}
	
	override protected function createChildren():void
	{
		super.createChildren();
		
		if(!bottomPadding)
		{
			bottomPadding = new UIComponent();
			bottomPadding.width = 1;
			bottomPadding.height = 1;
			addChildAt(bottomPadding,0);
		}
	}
	
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);

		if(resetItemRenderers)
		{
			resetItemRenderers = false;

			while(numChildren>1)
				removeChildAt(numChildren-1);
			
			itemRenderersByDataUid = new Dictionary(true);
		}

		var start:int = getTimer();
		var yCounter:Number = 0;
		var vGap:Number = getStyle("verticalGap");
		
		for each(var i:ISproutListItem in itemRenderersByDataUid)
			i.used = false;
		
		var itemWidth:Number = unscaledWidth - viewMetricsAndPadding.left - viewMetricsAndPadding.right;
		
		var highlightFlag:Boolean = false;
		
		var index:int = 0;
		for each(var data:ISproutListData in collection)
		{
			// find a itemRenderer if one exists
			var item:UIComponent = itemRenderersByDataUid[data.uid];
			
			if(!item)
			{
				item = itemRenderer.newInstance();
				(item as ISproutListItem).data = data;
				item.addEventListener(ResizeEvent.RESIZE, itemsResizeHandler, false, 0, true);
				itemRenderersByDataUid[data.uid] = item;
				addChildAt(item, index);
			}
			
			// layout itemRenderer
			var customItem:ISproutListItem = item as ISproutListItem;
			if(customItem)
			{
				customItem.highlight = highlightFlag;
				highlightFlag = !highlightFlag;
				
				customItem.used = true;
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

		bottomPadding.move(0, yCounter);
		yCounter += bottomPadding.height;
		
		if(yCounter != previousHeight)
		{
			if(bottomUp)
				verticalScrollPosition += yCounter-previousHeight;
			previousHeight = yCounter;
		}
		
		// purge unused itemRenderers
		for each(var itemToDelete:ISproutListItem in itemRenderersByDataUid)
		{
			if(!itemToDelete.used)
			{
				var comp:UIComponent = itemToDelete as UIComponent;
				comp.removeEventListener(ResizeEvent.RESIZE, itemsResizeHandler);
				removeChild(comp);
				
				var dataUid:String = (itemToDelete.data as ISproutListData).uid;
				delete itemRenderersByDataUid[dataUid];
			}
			System.gc();
		}
		var end:int = getTimer();
		//trace(end + " : " + (end - start) + " " + this + " creatingRows");
	}
	
	private function itemsResizeHandler(event:ResizeEvent):void
	{
		//trace(getTimer() + " resize " + event.target);
		invalidateDisplayList();
	}
	
}

}