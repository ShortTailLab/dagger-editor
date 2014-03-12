package excel
{
	import com.childoftv.xlsxreader.Worksheet;
	import com.childoftv.xlsxreader.XLSXLoader;
	
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;

	public class ExcelReader
	{			
		private var mExcelLoader:XLSXLoader = null;
		
		public function ExcelReader() {}
		public function parse( profile:File, onComplete:Function ):void {
			MapEditor.getInstance().addLog("正在加载"+profile.url+"..");
			
			var bytes:ByteArray = new ByteArray();
			var fstream:FileStream = new FileStream();
			fstream.open( profile, FileMode.READ );
			fstream.readBytes( bytes, 0, fstream.bytesAvailable );
			fstream.close();
			
			var self = this;
			this.mExcelLoader = new XLSXLoader();
			this.mExcelLoader.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				MapEditor.getInstance().addLog("excel加载成功");
				
				var titles:Vector.<String> = self.mExcelLoader.getSheetNames();
				if( titles.length <= 0 ) 
				{
					onComplete(null, "无sheet存在");
					return;
				}
				
				var sheet = self.mExcelLoader.worksheet(titles[0]);
				this.parseSheet(sheet, onComplete);
				self.mExcelLoader.close();
			});
			this.mExcelLoader.loadFromByteArray( bytes );
		}
		
		private const kSTART_LINE = 3;
		private function parseSheet( sheet:Worksheet, onComplete:Function ):void
		{	
			var indices:Array = [];
			var a_z:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
			var i:uint = 0, j:uint = 0;
			for( i=0; i<26; i++ ) 
				indices.push( a_z.charAt(i) );
			for( i=0; i<1; i++ )
				for( j=0; j<26; j++ )
					indices.push(a_z.charAt(i)+a_z.charAt(j));
			
			var key2indices = {};
			for( i=0; i<indices.length; i++ )
			{
				var key:String = sheet.getCellValue( indices[i]+String(kSTART_LINE) );
				if( key != "" )
					key2indices[key] = indices[i];
			}
			
			//
			var struct:Object = Data.getInstance().dynamic_args;
			if( !struct.hasOwnProperty("Chapter") || 
				!struct.hasOwnProperty("Level") )
			{
				onComplete(null, "无Chapter及Level数据结构定义");
				return;
			}
			
			var enum_type:Array = ["Chapter", "Level", "Monster", "Bullet"];
			var enum_must:Array = [
				{"chapter_id":"string", "chapter_name":"string"},
				{"level_id":"string","level_name":"string"},
				{"monster_id":"string", "monster_type":"string",
				 "monster_name":"string", "face":"string"}
			];
			var enum_key:Array  = ["chapter_id", "level_id", "monster_id"];
			var enum_configs:Array = [
				Utils.merge2Object(struct[enum_type[0]], enum_must[0]),
				Utils.merge2Object(struct[enum_type[1]], enum_must[1])
			];
			
			var raw:Object = {}; // ret
			var iterLine:int = kSTART_LINE+1;
			var nowChapter:String = "";
			var nowLevel:String = "";
			while(true)
			{
				var flag:Boolean = false; 
				var configs:Object = null;
				
				if( this.is_cell_valuable(sheet, key2indices, enum_key[0], iterLine) ) // Chapter 
				{
					configs = this.loadItems(sheet, key2indices, enum_type[0], enum_configs[0], iterLine);
					if( !configs ) 
					{
						onComplete(null, String(iterLine)+"章节未定义需要的列");
						return;
					}
					nowChapter = configs[enum_key[0]];
					if( !(nowChapter in raw) ) 
						raw[nowChapter] = {};
					else 
						Alert.show("存在重复的章节编号"+nowChapter);
					raw[nowChapter] = configs;
					raw[nowChapter].levels = {}; 
					flag = true;
				}
				
				if( nowChapter != "" &&
					this.is_cell_valuable(sheet, key2indices, enum_key[1], iterLine) ) // Level	
				{
					configs = this.loadItems(sheet, key2indices, enum_type[1], enum_configs[1], iterLine);
					if( !configs ) 
					{
						onComplete(null, String(iterLine)+"关卡未定义需要的列");
						return;
					}
					nowLevel = configs[enum_key[1]];
					if( !(nowLevel in raw[nowChapter].levels) )
						raw[nowChapter].levels[nowLevel] = {};
					else 
						Alert.show("存在重复的关卡编号"+nowLevel);
					raw[nowChapter].levels[nowLevel] = configs;
					raw[nowChapter].levels[nowLevel].monsters = {};
					flag = true;
				}
				
				if( nowChapter != "" && nowLevel != "" &&
					this.is_cell_valuable(sheet, key2indices, enum_key[2], iterLine) ) // Monster  
				{
					// get type
					var type:String = sheet.getCellValue(
						key2indices["monster_type"]+String(iterLine)
					);
					if( type == "" ) 
					{
						onComplete(null, String(iterLine)+"怪物未定义id");
						return;
					}
					var items:Object = Utils.merge2Object(struct[type], enum_must[2]);
					configs = this.loadItems(sheet, key2indices, type, items, iterLine);
					
					if( !configs ) 
					{
						onComplete(null, String(iterLine)+"怪物未定义需要的列");
						return;
					}
					var nowMonster:String = configs[enum_key[2]];
					raw[nowChapter].levels[nowLevel].monsters[nowMonster] = configs;
					flag = true;
					
					raw[nowMonster] = configs;
				}
				
				if(!flag) break;
				iterLine ++;
			}
			
			onComplete(raw);
			return true;
		}
		
		private function process_val(prefix:String, key:String, value:String):*
		{
			var struct:Object = Data.getInstance().dynamic_args;
			if( !(prefix in struct) ) 
				return value;
			
			var argType:String = struct[prefix][key];
			if(argType == "ccp")
				return Utils.arrayStr2ccpStr(value);
			else if(argType == "ccsize")
				return Utils.arrayStr2ccsStr(value);
			else if(argType == "int")
			{
				if( value == "" ) return 0;
				return int(value);
			}
			else if(argType == "float")
			{
				if( value == "" ) return 0;
				return Number(value);
			}
			else
				return value;
		}
		
		private function loadItems(sheet:Worksheet, t2i:Object, type:String, configs:Object, line:int):Object
		{
			var ret:Object = {};
			for( var key:String in configs )
			{
				if( !t2i.hasOwnProperty(key) )
				{
					return null;
				}
				var val:String = sheet.getCellValue(t2i[key]+String(line));
				ret[key] = this.process_val(type, key, val);
			}
			return ret;
		}
		
		private function is_cell_valuable(sheet:Worksheet, t2i:Object, key:String, line:int):Boolean
		{
			return sheet.getCellValue((t2i[key]+String(line))) != "";
		}
		
//		public function genLevel2MonsterTable():Object
//		{
//			var ret:Object = {};
//			for each( var item:* in this.mRawData )
//			{
//				var kids:Object = item.c;
//				for each( var l:* in kids )
//				{ 
//					ret[l.r.level_id] = l.c;
//				}
//			}
//			return ret;
//		}
//		
//		public function getChapterDataByLevelId(id:*):*
//		{
//			for each( var item:* in this.mRawData )
//			{
//				var kids:Object = item.c;
//				for each( var l:* in kids )
//				{
//					if( l.r.level_id == id )
//					{
//						return {
//							chapter_id : item.r.chapter_id,
//							chapter_name : item.r.chapter_name,
//							level_name : l.r.level_name
//						};
//					}
//				}
//			}
//			return null;
//		}
//		
//		public function genLevelIdList():Array
//		{
//			var ret:Array = [];
//			for each( var item:* in this.mRawData )
//			{
//				var kids:Object = item.c;
//				for each( var l:* in kids )
//				{ 
//					var level:Object = l.r;
//					ret.push(level.level_id);
//				}
//			}
//			return ret;
//		}
//		
//		public function genLevelXML():XML 
//		{
//			var ret:XML = <root></root>;
//			for each( var item:* in this.mRawData )
//			{
//				var chapter:Object = item.r;
//				var kids:Object = item.c;
//				
//				var lastNode:XML = new XML("<node label='" + chapter.chapter_name + "'></node>")
//				ret.appendChild(lastNode);
//				
//				var levelList:Array = new Array;
//				
//				for each(var l:Object in kids)
//				{
//					levelList.push(l.r);
//				}
//
//				// sort by level id
//				levelList.sortOn("level_id");
//				
//				for(var i=0; i<levelList.length; i++)
//				{
//					var level:Object = levelList[i];
//					
//					//var dd:String = "chapter name: {0}, id: {1}, level name: {2}";
//					//trace(StringUtil.substitute(dd, chapter.chapter_name, level.level_id, level.level_name));
//					
//					var node:XML = new XML("<level></level>");
//					node.@label = level.level_name;
//					node.@level_id = level.level_id;
//					
//					lastNode.appendChild(node);
//				}
//			}
//			return ret;
//		}
//
//		public function get data():Object {
//			return this.mMonsterData;
//		}
//		
//		public function get raw():Object {
//			return this.mRawData;
//		}
	}
}