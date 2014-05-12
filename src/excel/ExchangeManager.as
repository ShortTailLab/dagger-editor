package excel
{
	import com.as3xls.xls.ExcelFile;
	import com.as3xls.xls.Sheet;
	
	import flash.filesystem.File;
	import flash.utils.ByteArray;

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
		
		static public function export( chapter:Object ):ByteArray 
		{
			Utils.dumpObject( chapter );
			
			var i:int = 0, j:int = 0;
			var sheet:Sheet 	  = new Sheet();
			var levelFields:Array = [], monsterFields:Array = [];
			
			var levelData:Array = EditLevel.genLevelData();
			for( i=0; i<levelData.length; i++ )
				levelFields.push( levelData[i][ConfigPanel.kKEY] );
			
			sheet.resize(100, 20);
		
			var monsterData:Array = EditMonster.genData("","MonsterProfile");
			ExchangeManager.appendFields( monsterData, EditMonster.genData("", "TrapProfile") );
			ExchangeManager.appendFields( monsterData, EditMonster.genData("", "BulletProfile"));
			for( i=0; i<monsterData.length; i++ )
				monsterFields.push( monsterData[i][ConfigPanel.kKEY] );
		
			
			for( i=0; i<levelData.length; i++ )
			{
				sheet.setCell(0, i, levelData[i][ConfigPanel.kDESC] );
				sheet.setCell(1, i, levelData[i][ConfigPanel.kKEY] );
			}
			
			for( i=levelData.length; i<levelData.length+monsterData.length; i++ )
			{
				sheet.setCell(0, i, monsterData[i-levelData.length][ConfigPanel.kDESC] );
				sheet.setCell(1, i, monsterData[i-levelData.length][ConfigPanel.kKEY] );
			}
			
			var rowInd:int = 2;
			for each( var level:Object in chapter.levels )
			{
				var colInd:int = 0;
				for( i=0; i<levelFields.length; i++, colInd++ )
					sheet.setCell(rowInd, colInd, level[levelFields[i]]); 
				
				for each( var monster:Object in level.monsters )
				{
					var nowInd:int = colInd;
					for( i=0; i<monsterFields.length; i++, nowInd++ )
						sheet.setCell(rowInd, nowInd, monster[monsterFields[i]] );
					rowInd ++;
				}
				
				rowInd ++;
			}
			
			var xls:ExcelFile = new ExcelFile();
			xls.sheets.addItem( sheet );
			return xls.saveToByteArray();
		}
	}
}