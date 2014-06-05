package excel
{
	import com.childoftv.xlsxreader.Worksheet;
	import com.childoftv.xlsxreader.XLSXLoader;
	
	import excel.Grid;
	
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	public class ExcelConfigReader
	{
		public static function parse(path:String, name:String, onComplete:Function) : void
		{
			var file:File = new File(path);
			
			file.addEventListener(Event.COMPLETE, function(e:Event):void 
			{
				parseConfigFromBytes(file.data, name, onComplete);
			});
			file.load();
		}
		
		public static function parseConfigFromBytes(bytes:ByteArray, name:String, onComplete:Function) : void
		{
			var loader:XLSXLoader = new XLSXLoader;
			
			loader.addEventListener(Event.COMPLETE, function(e:Event):void
			{		
				
				var sheetNames:Vector.<String>= loader.getSheetNames(), flag:Boolean = false;
				for( var i=0; i<sheetNames.length; i++ )
					if( sheetNames[i] == name ) flag = true;
				if( !flag ) {
					onComplete(null);
					return;
				}
				
				var skillSheet:Worksheet = loader.worksheet(name);
				
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
					
					skillDict[ dict["id"] ] = dict;
				}
				
				onComplete(skillDict);
			});
			
			loader.loadFromByteArray(bytes);
		}
	}
}