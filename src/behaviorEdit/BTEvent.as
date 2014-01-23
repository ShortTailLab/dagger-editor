package behaviorEdit
{
	import flash.events.Event;
	
	public class BTEvent extends Event
	{
		static public var TREE_CHANGE:String = "tree_change";
		static public var LAID:String = "laid";
		
		public var bindingNode:BNode = null;
		
		public function BTEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}