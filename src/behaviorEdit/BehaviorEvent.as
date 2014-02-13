package behaviorEdit
{
	import flash.events.Event;
	
	public class BehaviorEvent extends Event
	{
		static public var ADD_BT:String = "add_bt";
		static public var BT_ADDED:String = "bt_added";
		static public var BT_REMOVED:String = "bt_removed";
		static public var CREATE_NEW_BT:String = "create_new_bt";
		static public var CREATE_BT_DONE:String = "create_bt_done";
		static public var CREATE_BT_CANCEL:String = "create_bt_cancel";
		static public var BT_XML_APPEND:String = "bt_xml_append";
		
		public var msg:String;
		
		public function BehaviorEvent(type:String, _msg:* = "")
		{
			super(type);
			msg = _msg;
		}
	}
}