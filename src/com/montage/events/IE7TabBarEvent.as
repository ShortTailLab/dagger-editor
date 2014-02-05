package com.montage.events
{
	import flash.events.Event;
	
	/**
	 * 给IE7TabBar提供事件支持
	 * @author Montage
	 */	
	public class IE7TabBarEvent extends Event
	{
		public static const NEW_ITEM_CLICK:String = "newItemClick";
		
		public function IE7TabBarEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}