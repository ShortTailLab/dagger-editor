package excel
{
	import com.childoftv.xlsxreader.Worksheet;
	import com.childoftv.xlsxreader.XLSXLoader;
	
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	import excel.Grid;
	
	public class SkillConfigReader
	{
		public static function parseSkillConfigFromPath(path:String, onComplete) : void
		{
			var file:File = new File(path);
			
			file.addEventListener(Event.COMPLETE, function(e:Event):void 
			{
				parseSkillConfigFromBytes(file.data, onComplete);
			});
			file.load();
		}
		
		public static function parseSkillConfigFromBytes(bytes:ByteArray, onComplete:Function) : void
		{
			var loader:XLSXLoader = new XLSXLoader;
			
			loader.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				var sheetNames:Vector.<String> = loader.getSheetNames();
				
				// check if we can find desired sheets
				if(sheetNames.indexOf("技能导表") < 0)
				{
					trace("cannot find skill sheet");
					return;
				}
		
				var skillSheet:Worksheet = loader.worksheet("技能导表");
				
				// get table range
				var height:int = skillSheet.getMaxRowCount("A");
				var width: int = skillSheet.getMaxHeightCount(2);
				
				// load worksheet to a grid
				var grid:Grid = skillSheet.toGrid(width, height);
				
				// clean up loader and sheets first
				skillSheet = null;
				loader.close();
				
				// do the conversion
				var skillDict:Object = {};
				var keyList:Array = grid.row(2);
				
				// build up json object
				for(var i:int = 3; i<grid.height; i++)
				{
					var valList:Array = grid.row(i);
					var dict:Object = {}
					
					for(var k:int=0; k<keyList.length; k++)
					{
						if( valList[k] == "" || keyList[k] == "" ) continue;
						var val:* = null;
						try{
							val = JSON.parse(valList[k]);
						}catch(e:Error)
						{
							val = valList[k];
						}
						dict[keyList[k]] = val;
					}
					
					if( !skillDict.hasOwnProperty(dict["id"]) )
						skillDict[ dict["id"] ] = {};
					skillDict[ dict["id"] ][ dict["level"] ] = dict;
				}
				
				for( var item:String in skillDict )
				{
					var max:Number = -1, max_level:int = 1;
					for( var level:String in skillDict[item] )
					{
						if( max < Number(level) )
						{
							max = Number(level);
							max_level = int(level);
						}
					}
					skillDict[item]["max_level"] = max_level;
				}
				
				onComplete(skillDict);
			});
			
			loader.loadFromByteArray(bytes);
		}
	}
}