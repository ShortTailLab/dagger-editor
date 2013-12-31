package excel
{
	import com.childoftv.xlsxreader.Worksheet;
	import com.childoftv.xlsxreader.XLSXLoader;
	
	import flash.events.Event;

	public class ExcelReader
	{
		public function ExcelReader()
		{
			
		}
		
		public function init(onComplete:Function=null):void {
			_onComplete = onComplete;
			_excelLoader = new XLSXLoader();
			_excelLoader.addEventListener(Event.COMPLETE, onExcelLoad);
			_excelLoader.load("Resource/levelData.xlsx");
		}
		
		private function onExcelLoad(e:Event):void {
			_enemyData = new Object();
			var workSheet:Worksheet = _excelLoader.worksheet("怪物表");
			
			for (var i:int = 3; ; i++) {
				trace("A"+i+" value: " + workSheet.getCellValue("A"+i));
				if (workSheet.getCellValue("A"+i) == "") {
					break;
				}
				var enemy:Object = new Object();
				_enemyData[workSheet.getCellValue("A"+i)] = enemy;
				enemy["face"] = workSheet.getCellValue("B"+i);
				enemy["name"] = workSheet.getCellValue("C"+i);
				if (int(workSheet.getCellValue("D"+i)) == 1) {
					enemy["bullet"] = JSON.parse(workSheet.getCellValue("K"+i));
				}
				if (int(workSheet.getCellValue("E"+i)) == 0) {
					enemy["move_type"] = 0;
				}
				else {
					enemy["move_type"] = int(workSheet.getCellValue("E"+i));
					enemy["move"] = JSON.parse(workSheet.getCellValue("F"+i));
				}
				enemy["level"] = int(workSheet.getCellValue("L"+i));
				enemy["health"] = int(workSheet.getCellValue("M"+i));
				enemy["attack"] = int(workSheet.getCellValue("N"+i));
				enemy["defend"] = int(workSheet.getCellValue("O"+i));
				enemy["bonus"] = int(workSheet.getCellValue("P"+i));
				enemy["rbonus"] = int(workSheet.getCellValue("Q"+i));				
			}
			
			if (_onComplete != null) {
				_onComplete.apply();
				_onComplete = null;
			}
		}
		
		public function get enemyData():Object {
			return _enemyData;
		}
		
		private var _excelLoader:XLSXLoader;
		private var _onComplete:Function;
		
		private var _enemyData:Object;		
	}
}