package
{
	import com.hurlant.crypto.symmetric.NullPad;
	
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
		//private var mSelectedComponentType:String = null;
		
		public var selectedComponentType:String = null;
	}
}