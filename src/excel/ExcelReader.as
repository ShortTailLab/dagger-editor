package excel
{
	import com.childoftv.xlsxreader.Worksheet;
	import com.childoftv.xlsxreader.XLSXLoader;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import manager.EventManager;
	import manager.EventType;
	import manager.GameEvent;

	public class ExcelReader
	{
		public function ExcelReader()
		{
			
		}
		
		public static function getInstance():ExcelReader {
			if (!_instance) {
				_instance = new ExcelReader();
			}
			return _instance;
		}
		
		public function initWithRelativePath( relativePath:String, onComplete:Function=null):void {
			_path = relativePath;
			_isPathNative = false;
			var file:File = new File(File.applicationDirectory.nativePath+"/"+relativePath);
			_lastModifiedDate = file.modificationDate;
			
			_onComplete = onComplete;
			_excelLoader = new XLSXLoader();
			_excelLoader.addEventListener(Event.COMPLETE, onExcelLoad);
			_excelLoader.load(relativePath);
			
			if (!_timer) {
				_timer = new Timer(5000);
				_timer.addEventListener(TimerEvent.TIMER, onTimer);
				_timer.start();
			}
		}
		
		public function initWithNativePath( nativePath:String ):void {
			_path = nativePath;
			_isPathNative = true;
			var file:File = new File(nativePath);
			_lastModifiedDate = file.modificationDate;

			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.READ);
			var byteArray:ByteArray = new ByteArray();
			fileStream.readBytes(byteArray,0,fileStream.bytesAvailable);
			
			_excelLoader = new XLSXLoader();
			_excelLoader.addEventListener(Event.COMPLETE, onExcelLoad);
			_excelLoader.loadFromByteArray(byteArray);
		}
		
		private function onTimer(e:TimerEvent):void {
			var file:File;
			if (_isPathNative) {
				file = new File(_path);
				if (file.exists && file.modificationDate.getTime() != _lastModifiedDate.getTime()) {
					trace("refreshing excel data from "+file.nativePath);
					initWithNativePath(_path);
				}
			}
			else {
				file = new File(File.applicationDirectory.nativePath+"/"+_path); 
				if (file.exists && file.modificationDate.getTime() != _lastModifiedDate.getTime()) {
					trace("refreshing excel data from "+file.nativePath);
					initWithRelativePath(_path);
				}
			}
		}
		
		private function onExcelLoad(e:Event):void {
			_excelLoader.removeEventListener(Event.COMPLETE, onExcelLoad);

			_enemyData = new Object();
			var workSheet:Worksheet = _excelLoader.worksheet("怪物表");
			
			for (var i:int = 3; ; i++) {
//				trace("A"+i+" value: " + workSheet.getCellValue("A"+i));
				if (workSheet.getCellValue("A"+i) == "") {
					break;
				}
				var enemy:Object = new Object();
				_enemyData[workSheet.getCellValue("A"+i)] = enemy;
				enemy["face"] = workSheet.getCellValue("B"+i);
				enemy["name"] = workSheet.getCellValue("C"+i);
				if (int(workSheet.getCellValue("D"+i)) == 0) {
					enemy["attack_type"] = 0;
					enemy["attack_args"] = new Object;
				}
				else
				{
					enemy["attack_type"] = 1;
					enemy["attack_args"] = JSON.parse(workSheet.getCellValue("K"+i));
				}
				if (int(workSheet.getCellValue("E"+i)) == 0) {
					enemy["move_type"] = 0;
				}
				else {
					enemy["move_type"] = int(workSheet.getCellValue("E"+i));
					enemy["move_args"] = JSON.parse(workSheet.getCellValue("F"+i));
				}
				enemy["level"] = int(workSheet.getCellValue("L"+i));
				enemy["health"] = int(workSheet.getCellValue("M"+i));
				enemy["attack_args"]["damage"] = int(workSheet.getCellValue("N"+i));
				enemy["defense"] = int(workSheet.getCellValue("O"+i));
				enemy["bonus"] = int(workSheet.getCellValue("P"+i));
				enemy["rbonus"] = int(workSheet.getCellValue("Q"+i));				
			}
			_excelLoader.close();

			if (_onComplete != null) {
				_onComplete.apply();
				_onComplete = null;
			}
			
			EventManager.getInstance().dispatchEvent(new GameEvent(EventType.EXCEL_DATA_CHANGE));
		}
		
		public function get enemyData():Object {
			return _enemyData;
		}
		
		private var _excelLoader:XLSXLoader;
		private var _onComplete:Function;
		private var _enemyData:Object;
		private var _timer:Timer;
		private var _lastModifiedDate:Date;
		private var _path:String;
		private var _isPathNative:Boolean;
		
		private static var _instance:ExcelReader;
	}
}