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
	import flash.utils.Dictionary;
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
			var workSheet:Worksheet = _excelLoader.worksheet("新表");
			var argToColDic:Dictionary = new Dictionary;
			var cols:String = "EFGHIJKLMNOPQRSTUVWXYZ";
			for(var k:int=0; k<cols.length; k++)
			{
				var colStr:String = cols.substr(k, 1);
				var arg:String = workSheet.getCellValue(colStr+"2");
				if(arg != "")
					argToColDic[arg] = colStr;
			}
					
			
			for (var i:int = 3; ; i++) {
//				trace("A"+i+" value: " + workSheet.getCellValue("A"+i));
				if (workSheet.getCellValue("A"+i) == "") {
					break;
				}
				var enemy:Object = new Object();
				_enemyData[workSheet.getCellValue("A"+i)] = enemy;
				enemy["face"] = workSheet.getCellValue("B"+i);
				enemy["type"] = workSheet.getCellValue("D"+i);
				
				var argsData:Object = Data.getInstance().dynamicArgs;
				if(argsData.hasOwnProperty(enemy["type"]))
					for(var arg in argsData[enemy["type"]])
					{
						if(enemy["type"] == "bullet" || enemy["type"] == "actor")
							enemy["nameCN"] = workSheet.getCellValue("C"+i);
						
						if(argToColDic.hasOwnProperty(arg))
						{
							var argType:String = argsData[enemy["type"]][arg];
							var value:String = workSheet.getCellValue(argToColDic[arg]+i);
							if(argType == "ccp")
								enemy[arg] = Utils.arrayStr2ccpStr(value);
							else if(argType == "ccsize")
								enemy[arg] = Utils.arrayStr2ccsStr(value);
							else if(argType == "int")
								enemy[arg] = int(value);
							else if(argType == "float")
								enemy[arg] = Number(value);
							else
								enemy[arg] = value;
						}
					}
				
				
				
				/*if(enemy["type"] == "bullet")
				{
					
					enemy["nameCN"] = workSheet.getCellValue("C"+i);
					enemy["offset"] = Utils.arrayStr2ccpStr(workSheet.getCellValue("E"+i));
					enemy["area"] = Utils.arrayStr2ccsStr(workSheet.getCellValue("F"+i));
					enemy["range"] = workSheet.getCellValue("G"+i);
					enemy["speed"] = workSheet.getCellValue("H"+i);
					enemy["damage"] = workSheet.getCellValue("I"+i);
				}
				else if(enemy["type"] == "actor")
				{
					enemy["nameCN"] = workSheet.getCellValue("C"+i);
					enemy["area"] = Utils.arrayStr2ccsStr(workSheet.getCellValue("F"+i));
					enemy["attack"] = int(workSheet.getCellValue("J"+i));
					enemy["health"] = int(workSheet.getCellValue("K"+i));
					enemy["defense"] = int(workSheet.getCellValue("L"+i));	
					
				}
				else if(enemy["type"] == "RollingStone")
				{
					enemy["speed"] = int(workSheet.getCellValue("H"+i));
					enemy["dps"] = int(workSheet.getCellValue("M"+i));
				}
				else if(enemy["type"] == "Meteorite")
				{
					enemy["damage"] = int(workSheet.getCellValue("I"+i));
					enemy["dps"] = int(workSheet.getCellValue("M"+i));
				}
				else if(enemy["type"] == "Bangalore")
				{
					enemy["area"] = Utils.arrayStr2ccsStr(workSheet.getCellValue("F"+i));
					enemy["dps"] = int(workSheet.getCellValue("M"+i));
				}
				
				/*enemy["level"] = int(workSheet.getCellValue("L"+i));
				enemy["health"] = int(workSheet.getCellValue("M"+i));
				//enemy["attack_args"]["damage"] = int(workSheet.getCellValue("N"+i));
				enemy["defense"] = int(workSheet.getCellValue("O"+i));
				enemy["bonus"] = int(workSheet.getCellValue("P"+i));
				enemy["rbonus"] = int(workSheet.getCellValue("Q"+i));	*/
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