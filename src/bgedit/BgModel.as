package bgedit
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.collections.ArrayCollection;
	
	import spark.collections.Sort;
	
	import manager.EventManager;
	import manager.EventType;
	import manager.GameEvent;

	public class BgModel
	{
		public function BgModel()
		{
		}
		
		public static function getInstance():BgModel {
			if (!_instance) {
				_instance = new BgModel();
			}
			return _instance;
		}
		
		public function init():void {
			_bgDict = new Object();
			_bgNameArray = new ArrayCollection();
			
			var file:File = File.desktopDirectory.resolvePath("bgConfig.json");
			if (!file.exists) {
				file = File.applicationDirectory.resolvePath("Resource/bgConfig.json");
			}
			if (file.exists) {
				var fileStream:FileStream = new FileStream();
				fileStream.open(file, FileMode.READ);
				var data:Object = JSON.parse(fileStream.readUTFBytes(fileStream.bytesAvailable));
				_bgDict = data;
				for (var bgName:String in _bgDict) {
					_bgNameArray.addItem(bgName);
				}
			}
			_bgNameArray.sort = new Sort();
			_bgNameArray.refresh();
			
			EventManager.getInstance().dispatchEvent(new GameEvent(EventType.INIT_BG_DATA_COMPLETE));
		}
		
		public function initWithData(data:Object):void {
			
		}
		
		public function get bgNameArray():ArrayCollection { return _bgNameArray; }

		/** bgName -> {bgConfig} */
		private var _bgDict:Object;
		/** [bgName] */
		private var _bgNameArray:ArrayCollection;
		
		private static var _instance:BgModel;
	}
}