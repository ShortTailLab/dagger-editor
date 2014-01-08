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
			
			
			var file:File = File.applicationDirectory.resolvePath("Resource/bgConfig.json");
		
			if (file.exists) {
				var fileStream:FileStream = new FileStream();
				fileStream.open(file, FileMode.READ);
				var data:Object = JSON.parse(fileStream.readUTFBytes(fileStream.bytesAvailable));
				_bgDict = data;
				for (var bgName:String in _bgDict) {
					var tmxFile:File;
					if ((_bgDict[bgName] as String).indexOf("file://") == 0) {
						tmxFile = new File(_bgDict[bgName]);
					}
					else {
						tmxFile = File.applicationDirectory.resolvePath(_bgDict[bgName]);
					}
					if (tmxFile.exists) {
						_bgNameArray.addItem(bgName);
					}
				}
			}
			_bgNameArray.sort = new Sort();
			_bgNameArray.refresh();
			
			EventManager.getInstance().dispatchEvent(new GameEvent(EventType.INIT_BG_DATA_COMPLETE));
		}
		
		public function addPair(name:String, url:String):void {
			if (_bgDict[name]) {
				_bgDict[name] = url;
				return;
			}
			_bgDict[name] = url;
			_bgNameArray.addItem(name);
			_bgNameArray.sort = new Sort();
			_bgNameArray.refresh();
			
			writeBgConfig();
		}
		
		public function removePair(index:int):void {
			if (_bgDict[_bgNameArray[index]]) {
				delete _bgDict[_bgNameArray[index]];
				_bgNameArray.removeItemAt(index);
				writeBgConfig();
			}
		}
		
		private function writeBgConfig():void {
			var file:File = new File(File.applicationDirectory.nativePath+"/Resource/bgConfig.json");
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes(JSON.stringify(_bgDict));
			fileStream.close();
		}
		
		public function get bgNameArray():ArrayCollection { return _bgNameArray; }
		public function get bgDict():Object { return _bgDict; }

		/** bgName -> url */
		private var _bgDict:Object;
		/** [bgName] */
		private var _bgNameArray:ArrayCollection;
		
		private static var _instance:BgModel;
	}
}