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
		
		private function parse():Boolean
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
			
			var enum_type:Array = ["Chapter", "Level", "Monster"];
			var enum_must:Array = [
				{"id":"string"},
				{"level_id":"string"},
				{"monster_id":"string", "monster_face":"string", "monster_name":"string"}
			];
			var enum_key:Array  = ["id", "level_id", "monster_id"];
			var enum_configs:Array = [
				Utils.merge2Object(struct[enum_type[0]], enum_must[0]),
				Utils.merge2Object(struct[enum_type[1]], enum_must[1]),
				Utils.merge2Object(struct[enum_type[2]], enum_must[2])
			];
				
			var iterLine:int = this.mStartLine;
			var nowChapter:String = "";
			var nowLevel:String = "";
			while(true)
			{	
				var flag = false;
				if( this.is_cell_valuable(enum_key[0], iterLine) ) // Chapter 
				{
					var configs = this.loadItems(enum_type[0], enum_configs[0], iterLine);
					if( !configs ) return false;
					nowChapter = configs[enum_key[0]];
					this.mRawData[nowChapter].r = configs;
					this.mRawData[nowChapter].c = {}; 
					flag = true;
				}
				if( nowChapter != "" &&
					this.is_cell_valuable(enum_key[1], iterLine) ) // Level	
				{
					var configs = this.loadItems(enum_type[1], enum_configs[1], iterLine);
					if( !configs ) return false;
					nowLevel = configs[enum_key[1]];
					this.mRawData[nowChapter].c[nowLevel].r = configs;
					this.mRawData[nowChapter].c[nowLevel].c = {};
					flag = true;
				}
				if( nowChapter != "" && nowLevel != "" &&
					this.is_cell_valuable(enum_key[2], iterLine) ) // Monster  
				{
					var configs = this.loadItems(enum_type[2], enum_configs[2], iterLine);
					if( !configs ) return false;
					var nowMonster = configs[enum_key[2]];
					this.mRawData[nowChapter].c[nowLevel].c[nowMonster] = configs;
					flag = true;
				}
				if(!flag) break;
				iterLine ++;
			}
			return true;
		}
		
		private function process_val(prefix:String, key:String, value:String):*
		{
			var struct:Object = Data.getInstance().dynamic_args;
			var argType:String = struct[prefix][key];
			if(argType == "ccp")
				return Utils.arrayStr2ccpStr(value);
			else if(argType == "ccsize")
				return Utils.arrayStr2ccsStr(value);
			else if(argType == "int")
				return int(value);
			else if(argType == "float")
				return Number(value);
			else
				return value;
		}
		
		private function loadItems(type:String, configs:Object, line:int):Object
		{
			var ret:Object = {};
			for( var key:String in configs )
			{
				if( !this.mTitle2col.hasOwnProperty(key) )
				{
					Alert.show(type+" 未定义需要的字段 : "+key);
					return null;
				}
				var val = this.mSheet.getCellValue(this.mTitle2col[key]+String(line));
				ret[key] = this.process_val(type, key, val);
				if( ret[key] == "" )
				{
					Alert.show(type+" 未定义需要的字段 : "+key);
					return null;
				}
			}
			return ret;
		}
		
		private function is_cell_valuable(key:String, line:int):Boolean
		{
			return mSheet.getCellValue(mTitle2col[key]+String(line)) != "";
		}

		private function loadChapter(line:int, m:Object):int
		{
			var container:Object = {};
			var must:String = ["id"];
			for( var item:* in must )
			{
				if( !this.mTitle2col.hasOwnProperty(item) ) 
				{
					Alert.show("Chapter 缺少必有字段："+item);
					return -2;
				}
				var val = this.mSheet.getCellValue(this.mTitle2col[item]+String(line));
				container[item] = this.process_val("Chapter", item, val);
			}
			
			for( var item:* in struct )
			{
				if( 
				var val = this.mSheet
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