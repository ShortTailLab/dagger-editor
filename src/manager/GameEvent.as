package manager
{
	import flash.events.Event;
	
	public class GameEvent extends Event
	{
		public function GameEvent(type:String, data:Object=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			_data = data;
			super(type, bubbles, cancelable);
		}
		
		public function get data():Object { return _data; };
		
		private var _data:Object;
	}
}