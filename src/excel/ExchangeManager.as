package excel
{
	import com.as3xls.xls.ExcelFile;
	import com.as3xls.xls.Sheet;
	
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;

	public class ExchangeManager
	{
		public function ExchangeManager()
		{}
		
		static protected function appendFields( to:Array, from:Array ):void
		{
			var i:int = 0, j:int = 0;
			for( i=0; i<from.length; i++ )
			{
				var flag:Boolean = false;
				for( j=0; j<to.length; j++ )
				{
					if( to[j][ConfigPanel.kKEY] == from[i][ConfigPanel.kKEY] )
					{
						flag = true;
						break;
					}
				}
				if( flag ) continue;
				
				to.push( from[i] );
			}
		}
		
		static public function unserializeChapterFromFile( onComplete:Function  ):void
		{
			var browser:File = new File(Data.getInstance().conf["excel.path.cache"]);
			browser.browseForOpen("请选择上传的Excel文件");
			browser.addEventListener(Event.SELECT, function(e:Event):void
			{
				var profile:File = e.target as File;
				Data.getInstance().setEditorConfig("excel.path.cache", profile.nativePath);
				
				var bytes:ByteArray = new ByteArray();
				var fstream:FileStream = new FileStream();
				fstream.open( profile, FileMode.READ );
				fstream.readBytes( bytes, 0, fstream.bytesAvailable );
				fstream.close();
				
				var xls:ExcelFile = new ExcelFile();
				xls.loadFromByteArray(bytes);
				
				var sheet:Sheet = xls.sheets[0];
				ExchangeManager.updateChapterFromSheet(sheet, onComplete);
			});
		}
		
		// read a row
		static protected function getRowValues(sheet:Sheet, rowIndex:uint): Array
		{
			var row:Array = new Array;
			for(var i=0; i<sheet.cols; i++)
			{
				row.push(sheet.getCell(rowIndex, i).value);
			}
			return row;
		}
		
		// read a level from a row
		static protected function readLevelFromRow(row:Array, keyMap:Object): Object
		{
			var argList = EditLevel.genLevelData();
			var argKeys:Array = [];
			var levelInfo = {};
			
			for(var i=0; i<argList.length; i++)
			{
				var key = argList[i][ConfigPanel.kKEY];
				var type = argList[i][ConfigPanel.kTYPE];
				var rawValue = row[keyMap[key]];
				var value = strToVal(rawValue, type);
				// do not add entry if its value is not defined
				if(value != null)
					levelInfo[key] = value; 
			}
			
			levelInfo["monsters"] = {};
			
			return levelInfo;
		}
		
		// read a monster from row
		static protected function readMonsterFromRow(row:Array, keyMap:Object): Object
		{
			var type:String = strToVal(row[keyMap.type], "string");
			if(type == null || type == "")
				return null;
			
			var argList:Array = EditMonster.genArgsTemplate(type);
			var monster:* = {};
			for(var i=0; i<argList.length; i++)
			{
				var key:String = argList[i][ConfigPanel.kKEY];
				var type:String = argList[i][ConfigPanel.kTYPE];
				var rawValue = row[keyMap[key]];
				var value = strToVal(rawValue, type);
				// do not add entry if its value is not defined
				if(value != null)
					monster[key] = value;
			}
			
			return monster;
		}
		
		static protected function updateChapterFromSheet( sheet:Sheet, onComplete:Function ):void
		{
			var levelArgs:Array = null;
			var monsterArgs:Array = EditMonster.genBaseArgsTemplate("MonsterProfile");
			var trapArgs:Array = EditMonster.genBaseArgsTemplate("TrapProfile");
			var bulletArgs:Array = EditMonster.genBaseArgsTemplate("BulletProfile");
			
			var chapterId = sheet.getCell(2, 0);
			
			var keys = getRowValues(sheet, 1);
			
			// convert array of keys to map of key => col_index
			var keyMap = {};
			for(var i=0; i<keys.length; i++)
				keyMap[keys[i]] = i;
			
			var levelList:Array = [];
			var currentLevel:* = null;
			
			// place monster profiles into level buckets
			for(var rowIndex = 2; rowIndex < sheet.rows; rowIndex++)
			{
				var rowData:Array = getRowValues(sheet, rowIndex);
				if(rowData[keyMap.level_id])
				{
					if(currentLevel)
					{
						levelList.push(currentLevel); 
						currentLevel = null;
					}
					currentLevel = readLevelFromRow(rowData, keyMap);
					trace("parsing level " + currentLevel.level_id);
				}

				var obj = readMonsterFromRow(rowData, keyMap);
				if(obj)
					currentLevel["monsters"][obj.monster_id] = obj;
			}

			// do not forget to push the last level
			levelList.push(currentLevel);
			currentLevel = null;
			
			for(var i:int=0; i<levelList.length; i++)
			{
				var level:* = levelList[i];
				
				var monsters = level.monsters;
				
				// erase this entry, so updateLevel will not overwrite
				delete level.monsters; 
				Data.getInstance().updateLevel(level.level_id, level);

				for each(var monster:* in monsters)
				{ 
					Data.getInstance().updateMonster(level.level_id, monster.monster_id, monster);
				}
			}
		}
		
		static protected function strToVal(val:String, type:String)
		{
			switch(type)
			{
				case "string":
				case "combo_box":
					return val;
				default:
				{
					if(val == "" || val == null)
						return null;
					else
						return JSON.parse(val);
				}
			}
			
			throw "Unknown type";
		}
		
		static public function valToStr(o:*, type:String): String
		{
			switch(type)
			{
				case "string":
				case "combo_box":
					return o;
				default: {
					var value = JSON.stringify(o);
					if(o == undefined)
						value = "";
					if(value == null)
						value = "";
					return value;
				}
			}
			throw "Unknown type";
		}
		
		static public function serialize( chapter:Object ):void 
		{
			var level:Object = {}, monster:Object = {};
			var sheet:Sheet 	  = new Sheet();
			
			var levelArgs:Array = EditLevel.genLevelData();
						
			
			// find the types of all monsters
			var usedMonsterTypes = {};
			for(var levelId in chapter.levels)
			{
				var level = chapter.levels[levelId];
				for(var monsterId in level.monsters)
				{
					var monster = level.monsters[monsterId];
					usedMonsterTypes[monster.type] = true;
				}
			}
			
			var monsterArgs:Array = []; 
			for(var key:String in usedMonsterTypes)
			{
				var args = EditMonster.genArgsTemplate(key); //EditMonster.genData(key, Data.getInstance().typeToProfileType(key));
				ExchangeManager.appendFields(monsterArgs, args);
			}
			
			// load arguments
			//var monsterArgs:Array = EditMonster.genBaseArgsTemplate("MonsterProfile");
			ExchangeManager.appendFields( monsterArgs, EditMonster.genBaseArgsTemplate("TrapProfile") );
			ExchangeManager.appendFields( monsterArgs, EditMonster.genBaseArgsTemplate("BulletProfile") );

			var totalRow:int = 10;
			for each( level in chapter.levels )
			{
				totalRow +=2;
				for each( monster in level.monsters )
					totalRow ++;
			}
			
			sheet.resize( totalRow, monsterArgs.length + levelArgs.length );
		
			for(var i=0; i<levelArgs.length; i++ )
			{
				sheet.setCell(0, i, levelArgs[i][ConfigPanel.kDESC] );
				sheet.setCell(1, i, levelArgs[i][ConfigPanel.kKEY] );
			}
			
			for(var i=levelArgs.length; i<levelArgs.length+monsterArgs.length; i++ )
			{
				sheet.setCell(0, i, monsterArgs[i-levelArgs.length][ConfigPanel.kDESC] );
				sheet.setCell(1, i, monsterArgs[i-levelArgs.length][ConfigPanel.kKEY] );
			}
			
			var rowInd:int = 2;
			for each( level in chapter.levels )
			{
				var colInd:int = 0;
				for(var i=0; i<levelArgs.length; i++, colInd++ )
				{
					var argKey = levelArgs[i][ConfigPanel.kKEY];
					var argType = levelArgs[i][ConfigPanel.kTYPE];
					var value:String = valToStr(level[argKey], argType);
					sheet.setCell(rowInd, colInd, value); 
				}
				
				var monsters:Object = Data.getInstance().getMonstersByLevelId( level.level_id );
				var traps:Object = Data.getInstance().getTrapsByLevelId( level.level_id );
				var bullets:Object = Data.getInstance().getBulletsByLevelId( level.level_id );
				
				var targets:Array = [];
				for each( monster in Data.getInstance().getMonstersByLevelId( level.level_id ) )
					targets.push( monster );
				for each( monster in Data.getInstance().getBulletsByLevelId( level.level_id ) )
					targets.push( monster );
				for each( monster in Data.getInstance().getTrapsByLevelId( level.level_id ) )
					targets.push( monster );		
				
				for each( monster in targets )
				{
					var nowInd:int = colInd;
					for(var i=0; i<monsterArgs.length; i++, nowInd++ )
					{
						var argKey = monsterArgs[i][ConfigPanel.kKEY];
						
						if( argKey in monster ) 
						{
							var type = monsterArgs[i][ConfigPanel.kTYPE];
							var value:String = valToStr(monster[argKey], type);
							sheet.setCell( rowInd, nowInd, value);
						}
					}
					rowInd++;
				}
			}
			
			var xls:ExcelFile = new ExcelFile();
			xls.sheets.addItem( sheet );
			
			var bytes:ByteArray = xls.saveToByteArray("cn-gb");
			
			var fr:FileReference = new FileReference( );
			fr.save(bytes, chapter.id+".xls");
		}
	}
}