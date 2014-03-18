package tools
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
				/*
				for(var i:int = 0; i<sheetNames.length; i++)
					trace("loaded sheet name " + sheetNames[i]);
				*/
				
				// check if we can find desired sheets
				if(sheetNames.indexOf("技能导表") < 0)
				{
					trace("cannot find skill sheet");
					return;
				}
		
				var skillSheet:Worksheet = loader.worksheet("技能导表");
				var height:int = skillSheet.getMaxRowCount("A");
				var width: int = skillSheet.getMaxHeightCount(2);
				
				var grid:Grid = skillSheet.toGrid(width, height);
				
				// clean up loader and sheets first
				skillSheet = null;
				loader.close();
				
				// do the conversion
				var skillDict = {};
				var keyList = grid.row(1);
				
				for(var i:int = 2; i<grid.height; i++)
				{
					var valList:Array = grid.row(i);
					var dict:Object = {}
					
					for(var k:int=0; k<keyList.length; k++)
						dict[keyList[k]] = valList[k];
					
					skillDict[dict[keyList[0]]] = dict;
				}
				
				onComplete(skillDict);
			});
			
			loader.loadFromByteArray(bytes);
		}
	}
}