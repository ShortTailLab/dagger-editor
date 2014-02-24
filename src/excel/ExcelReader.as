package excel
{
	import com.childoftv.xlsxreader.Worksheet;
	import com.childoftv.xlsxreader.XLSXLoader;
	
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	
	import manager.EventManager;
	import manager.EventType;
	import manager.GameEvent;

	public class ExcelReader
	{
		private var _onComplete:Function;
		private var _timer:Timer;
		private var _lastModifiedDate:Date;
		
		private var mExcelLoader:XLSXLoader;
		private var mSheet:Worksheet;
		private var mExcelPath:String;
		private var mRawData:Object;
		private var mMonsterData:Object;
		
		private var mStartLine:int = 3;
		private var mTitle2col:Object;
		
		private var mChapterLength:int;
		private var mLevelLength:int;
		
		public function ExcelReader() {}
		public function initWithNativePath( nativePath:String ):void {
			mExcelPath = nativePath;
			var file:File = new File(nativePath);

			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.READ);
			var byteArray:ByteArray = new ByteArray();
			fileStream.readBytes(byteArray,0,fileStream.bytesAvailable);
			
			mExcelLoader = new XLSXLoader();
			mExcelLoader.addEventListener(Event.COMPLETE, onExcelLoad);
			mExcelLoader.loadFromByteArray(byteArray);
		}
		
		private function onExcelLoad(e:Event):void {
			mExcelLoader.removeEventListener(Event.COMPLETE, onExcelLoad);

			mRawData = {};
			mSheet = mExcelLoader.worksheet("新表");
			var argToColDic:Dictionary = new Dictionary;
			
			// colume search range
			var target_cols:Array = [];
			for( var i:int ='A'; i<='Z'; i++ ) target_cols.push(i);
			for( var i:int ='A'; i<='Z'; i++ )
				for( var j:int='A'; j<'Z'; j++ )
					target_cols.push(String(i)+String(j));
			
			// mapping table
			mTitle2col = {};
			for(var k:int=0; k<target_cols.length; k++)
			{
				var val:String = mSheet.getCellValue(target_cols[k]+String(mStartLine));
				if(val != "")
					mTitle2col[val] = target_cols[k];
			}	
		}
		
		public function parse():Boolean
		{
			// get data stucture
			var struct:Object = Data.getInstance().dynamic_args;
			if( !struct.hasOwnProperty("Chapter") ||
				!struct.hasOwnProperty("Level") )
			{
				Alert.show("dynamic_args缺少Chapter以及Level的定义");
				return false;
			}
			
			this.mChapterLength = Utils.getObjectLength(struct.Chapter);
			this.mLevelLength = Utils.getObjectLength(struct.Level);
			
			// protocal : -1 -> 'stop', -2 -> 'error' 
			var next:int = this.loadChapter(mStartLine, struct);
			if( next == -2 ) return false;
			while( next != -1 )
			{
				if( next == -2 ) return false;
				next = this.loadChapter(next, struct);
			}
			return true;
		}

		private function loadChapter(line:int, struct:Object):int
		{
			var must:Object = {"id":true};
			for( var item:* in must )
			{
				
			}
			for( var item:* in struct )
			{
			}
			return 0;
		}
		
		private function loadLevel()
		{
		}
		
		private function loadMonster()
		{
			for (var i:int = 3; ; i++) {
//				trace("A"+i+" value: " + workSheet.getCellValue("A"+i));
				if (workSheet.getCellValue("A"+i) == "") {
					break;
				}
				var enemy:Object = new Object();
				mRawData[workSheet.getCellValue("A"+i)] = enemy;
				enemy["face"] = workSheet.getCellValue("B"+i);
				enemy["type"] = workSheet.getCellValue("D"+i);
				
				var argsData:Object = Data.getInstance().dynamic_args;
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
			}
			mExcelLoader.close();

			if (_onComplete != null) {
				_onComplete.apply();
				_onComplete = null;
			}
			
			EventManager.getInstance().dispatchEvent(new GameEvent(EventType.EXCEL_DATA_CHANGE));
		}
		
		private function addressVal()
		{
			
		}
		
		public function get data():Object {
			return mMonsterData;
		}
		
		public function get raw():Object {
			return mRawData;
		}
	}
}