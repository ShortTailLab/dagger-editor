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
		
		// ---> scene scalor
		private const kSceneScalor:Number = 0.5;
		public function get sceneScalor(): Number {
			return this.kSceneScalor;
		}
		
		//
		public static const CURRENT_LEVEL_CHANGE:String = "runtime.current.level.change";
		private var mCurrentLevelID:String = null;
		public function get currentLevelID(): String {
			return this.mCurrentLevelID;
		}
		public function set currentLevelID(v:String):void {
			this.mCurrentLevelID = v;
			this.dispatchEvent( new Event(Runtime.CURRENT_LEVEL_CHANGE) );
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
		public static const PROFLE_DATA_CHANGE:String = "runtime.profile.data.change";
		public function onProfileDataChange():void {
			this.dispatchEvent( new Event(Runtime.PROFLE_DATA_CHANGE) );
		}
		
		// 
		public static const CANCEL_SELECTION:String = "runtime.cancel.selection";
		public function onCancelSelection():void {
			this.dispatchEvent( new Event(Runtime.CANCEL_SELECTION) );
		}
	}
}