package
{
	import flash.events.EventDispatcher;

	public class Runtime extends EventDispatcher
	{
		////// entrance
		private static var gRuntimeInstance:Runtime = null;
		public static function getInstance():Runtime
		{
			if( !gRuntimeInstance) gRuntimeInstance = new Runtime;
			return gRuntimeInstance;
		}
		
		//
		public var selectedComponentType:String = null;
		public var selectedFormationType:String = null;
	}
}