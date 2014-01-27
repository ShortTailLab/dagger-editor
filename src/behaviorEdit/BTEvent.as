package behaviorEdit
{
	import flash.events.Event;
	
	public class BTEvent extends Event
	{
		static public var TREE_CHANGE:String = "tree_change";
		static public var LAID:String = "laid";
		static public var HAS_EDITED:String = "has_edit";
		
		public var bindingNode:BNode = null;
		
		public function BTEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}