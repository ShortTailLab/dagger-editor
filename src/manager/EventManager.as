package manager
{
	import flash.events.EventDispatcher;
	
	public class EventManager extends EventDispatcher
	{	
		public static function getInstance():EventManager {
			if (!_instance) {
				_instance = new EventManager();
			}
			return _instance;
		}
		
		private static var _instance:EventManager;
	}
}