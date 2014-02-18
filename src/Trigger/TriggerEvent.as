// ActionScript file
package Trigger
{
	import flash.events.Event;
	public class TriggerEvent extends Event
	{
		static public var ADD_TRIGGER:String = "add_trigger";
		static public var REMOVE_TRIGGER:String = "remove_trigger";
		
		public var msg:String = "";
		public var from:TNode = null;
		
		public function TriggerEvent(owner:TNode, type:String, _msg:* = "")
		{
			super(type);
			this.msg = _msg;
			this.from = owner;
		}
	}
}