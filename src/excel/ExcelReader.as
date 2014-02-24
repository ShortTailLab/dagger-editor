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
		private var mMonsterData:Object = {};
		
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
			var a_z:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
			var i:uint = 0, j:uint = 0;
			for( i=0; i<26; i++ ) target_cols.push( a_z.charAt(i) );
			for( i=0; i<2; i++ )
				for( j=0; j<26; j++ )
				{
					target_cols.push(a_z.charAt(i)+a_z.charAt(j));
				}
			// mapping table
			this.mTitle2col = {};
			for(var k:int=0; k<target_cols.length; k++)
			{
				var key:String = this.mSheet.getCellValue(target_cols[k]+String(mStartLine));
				if(key != "")
					this.mTitle2col[key] = target_cols[k];
			}	
			
			if( this.parse() )
			{
				EventManager.getInstance().dispatchEvent(
					new GameEvent(EventType.EXCEL_DATA_CHANGE)
				);
			}
			
			Utils.dumpObject(this.mRawData);
			
			mExcelLoader.close();
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
			
			var enum_type:Array = ["Chapter", "Level", "Monster", "Bullet"];
			var enum_must:Array = [
				{"chapter_id":"string"},
				{"level_id":"string"},
				{"monster_id":"string", "monster_type":"string",
				 "monster_name":"string", "face":"string"}
			];
			var enum_key:Array  = ["chapter_id", "level_id", "monster_id"];
			var enum_configs:Array = [
				Utils.merge2Object(struct[enum_type[0]], enum_must[0]),
				Utils.merge2Object(struct[enum_type[1]], enum_must[1])
			];
			
			var iterLine:int = this.mStartLine+1;
			var nowChapter:String = "";
			var nowLevel:String = "";
			while(true)
			{
				var flag:Boolean = false; var configs:Object = null;
				if( this.is_cell_valuable(enum_key[0], iterLine) ) // Chapter 
				{
					configs = this.loadItems(enum_type[0], enum_configs[0], iterLine);
					if( !configs ) return false;
					nowChapter = configs[enum_key[0]];
					if( !(nowChapter in this.mRawData) ) 
						this.mRawData[nowChapter] = {};
					this.mRawData[nowChapter].r = configs;
					this.mRawData[nowChapter].c = {}; 
					flag = true;
				}
				if( nowChapter != "" &&
					this.is_cell_valuable(enum_key[1], iterLine) ) // Level	
				{
					configs = this.loadItems(enum_type[1], enum_configs[1], iterLine);
					if( !configs ) return false;
					nowLevel = configs[enum_key[1]];
					if( !(nowLevel in this.mRawData[nowChapter].c) )
						this.mRawData[nowChapter].c[nowLevel] = {};
					this.mRawData[nowChapter].c[nowLevel].r = configs;
					this.mRawData[nowChapter].c[nowLevel].c = {};
					flag = true;
				}
				if( nowChapter != "" && nowLevel != "" &&
					this.is_cell_valuable(enum_key[2], iterLine) ) // Monster  
				{
					// get type
					var type:String = this.mSheet.getCellValue(
						this.mTitle2col["monster_type"]+String(iterLine)
					);
					if( type == "" ) return false;
					var items:Object = Utils.merge2Object(struct[type], enum_must[2]);
					//trace("---------------------- items");
					//Utils.dumpObject(items);
					configs = this.loadItems(enum_type[2], items, iterLine);
					//trace("---------------------- configs");
					//Utils.dumpObject(configs);
					if( !configs ) return false;
					var nowMonster:String = configs[enum_key[2]];
					this.mRawData[nowChapter].c[nowLevel].c[nowMonster] = configs;
					flag = true;
					
					this.mMonsterData[nowMonster] = configs;
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
					Alert.show(type+" 未定义需要的列 : "+key);
					return null;
				}
				var val:String = this.mSheet.getCellValue(this.mTitle2col[key]+String(line));
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
			return mSheet.getCellValue((mTitle2col[key]+String(line))) != "";
		}

		public function get data():Object {
			return this.mMonsterData;
		}
		
		public function get raw():Object {
			return this.mRawData;
		}
	}
}