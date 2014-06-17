package
{
	import com.hurlant.crypto.symmetric.NullPad;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mapEdit.Component;

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
		private var mCurrentLevelID:String = "100004";
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
		
		public function get selectedComponentType():String {
			return this.mSelectedComponentType;
		}
		
		public function set selectedComponentType( v:String ):void {
			this.mSelectedComponentType = v;
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
		
		//
		public static const ON_PASTE_TARGET_CHANGE:String = "runtime.on.paste.target.change";
		private var mPasteTarget:String = null;
		private var mPasteTargetLevel:String = null;
		public function get pasteTargetLevel():String { return this.mPasteTargetLevel; }
		public function get pasteTarget():String {
			return this.mPasteTarget;
		}
		public function set pasteTarget(v:String):void {
			this.mPasteTarget = v;
			this.mPasteTargetLevel = Runtime.getInstance().currentLevelID;
			this.dispatchEvent( new Event(Runtime.ON_PASTE_TARGET_CHANGE) );	
		}
	}
}