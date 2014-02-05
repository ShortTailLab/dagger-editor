package com.montage.controls
{
	import com.montage.events.IE7TabBarEvent;
	
	import flash.events.MouseEvent;
	
	import mx.controls.Button;
	import mx.controls.TabBar;
	
	/**
	 * 点击新建tab时所要派发的事件
	 */
	[Event(name="newItemClick", type="com.montage.events.IE7TabBarEvent")]
	
	/**
	 * 
	 * @author Montage
	 */	
	public class IE7TabBar extends TabBar
	{
		public function IE7TabBar()
		{
			super();
		}
		
		[Embed(source="/com/montage/icons/tab_add.png")]
		public var addIcon:Class;
		
		private var _newTab:Button;
		
		protected function mouseOutHandler( event:MouseEvent ):void
		{
			var but:Button = Button( event.currentTarget );
			but.setStyle("icon", null);
		}
		
		protected function mouseOverHandler( event:MouseEvent ):void
		{
			var but:Button = Button( event.currentTarget );
			but.setStyle("icon", addIcon);
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			_newTab = createNavItem("") as Button;
			_newTab.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
			_newTab.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			if( !contains(_newTab) )
				addChild(_newTab);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if( _newTab )
			{
				_newTab.toggle = false;
				_newTab.setStyle("paddingLeft", 5);
				_newTab.setStyle("paddingRight", 5);
				_newTab.width = 30;
			}
		}
		
		override protected function clickHandler(event:MouseEvent):void
		{
			if( event.currentTarget == _newTab )
			{
				var evt:IE7TabBarEvent = new IE7TabBarEvent( IE7TabBarEvent.NEW_ITEM_CLICK );
				dispatchEvent(evt);
				return;
			}
			super.clickHandler(event);
		}
		
	}
}