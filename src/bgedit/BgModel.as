package bgedit
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.collections.ArrayCollection;
	
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
			var directory:File = File.desktopDirectory.resolvePath("levelConfigs");
			if (directory.exists && directory.isDirectory) {
				var list:Array = directory.getDirectoryListing();
				for each(var file:File in list) {
					if (!file.isDirectory && file.name.indexOf(".json") != -1) {
						var fileStream:FileStream = new FileStream();
						fileStream.open(file, FileMode.READ);
						var data:Object = JSON.parse(fileStream.readUTFBytes(fileStream.bytesAvailable));
						_bgDict[file.name] = data;
						_bgNameArray.addItem(file.name);
					}
				}
			}
			
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