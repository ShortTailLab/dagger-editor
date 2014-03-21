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
		private var mCurrentLevelID:String = null;
		public function get currentLevelID(): String {
			return this.mCurrentLevelID;
		}
		public function set currentLevelID(v:String):void {
			this.mCurrentLevelID = v;
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
		
		// 
		public static const FORMATION_DATA_CHANGE:String = "runtime.formation.data.change";
		public function onFormationDataChange():void {
			this.dispatchEvent( new Event(Runtime.FORMATION_DATA_CHANGE) );
		}
		
		//
		public static const PROFILE_DATA_CHANGE:String = "runtime.profile.data.change";
		public function onProfileDataChange():void {
			this.dispatchEvent( new Event(Runtime.PROFILE_DATA_CHANGE) );
		}
	}
}