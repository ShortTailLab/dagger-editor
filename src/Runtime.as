package
{
	import flash.events.Event;
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
		public static const SELECT_DATA_CHANGE:String = "runtime.select.data.change";
		private var mSelectedComponentType:String = null;
		private var mSelectedFormationType:String = null;
		
		public function get selectedComponentType():String {
			return this.mSelectedComponentType;
		}
		public function get selectedFormationType():String {
			return this.mSelectedFormationType;	
		}
		
		public function set selectedComponentType( v:String ):void {
			this.mSelectedComponentType = v;
			this.dispatchEvent( new Event(Runtime.SELECT_DATA_CHANGE) );
		}
		
		public function set selectedFormationType( v:String):void {
			this.mSelectedFormationType = v;
			this.dispatchEvent( new Event(Runtime.SELECT_DATA_CHANGE) );
		}
	}
}