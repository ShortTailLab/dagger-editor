package behaviorEdit
{
	import flash.events.Event;
	
	public class BehaviorEvent extends Event
	{
		static public var ADD_BT:String = "add_bt";
		static public var REMOVE_BT:String = "remove_bt";
		
		public var msg:String = "";
		
		public function BehaviorEvent(type:String)
		{
			super(type);
		}
	}
}