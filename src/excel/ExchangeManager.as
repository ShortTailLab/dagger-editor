package excel
{
	import com.as3xls.xls.ExcelFile;
	import com.as3xls.xls.Sheet;
	import com.childoftv.xlsxreader.Worksheet;
	import com.childoftv.xlsxreader.XLSXLoader;
	
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileReference;
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
		
		static public function unserialize( onComplete:Function  ):void
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
				
				ExchangeManager.unserialize2( bytes, onComplete );
			});
		}
		
		static protected function unserialize2( bytes:ByteArray, onComplete ):void
		{
			var loader:XLSXLoader = new XLSXLoader();
			loader.addEventListener(Event.COMPLETE, function(e:Event):void
			{
				var titles:Vector.<String> = loader.getSheetNames();
				if( titles.length <= 0 )
				{
					onComplete("【错误】无sheet存在");
					return;
				}
				
				var sheet:Worksheet = loader.worksheet( titles[0] );
				ExchangeManager.unserialize3( sheet, onComplete );
				loader.close();
			});
			loader.loadFromByteArray( bytes );
		}
		
		static protected function unserialize3( sheet:Worksheet, onComplete:Function ):void
		{
			var i:int = 0, j:int = 0;
			var monsterFields:Array = [];
			var monsterData:Array = EditMonster.genData("","MonsterProfile");
			ExchangeManager.appendFields( monsterData, EditMonster.genData("", "TrapProfile") );
			ExchangeManager.appendFields( monsterData, EditMonster.genData("", "BulletProfile"));
			for( i=0; i<monsterData.length; i++ )
				monsterFields.push( monsterData[i][ConfigPanel.kKEY] );
			
			var rowInd = 2;
			while(true){
			}
		}
		
		static public function serialize( chapter:Object ):void 
		{
			var i:int = 0, j:int = 0, level:Object = {}, monster:Object = {};
			var sheet:Sheet 	  = new Sheet();
			var levelFields:Array = [], monsterFields:Array = [];
			
			var levelData:Array = EditLevel.genLevelData();
			for( i=0; i<levelData.length; i++ )
				levelFields.push( levelData[i][ConfigPanel.kKEY] );
			
			var monsterData:Array = EditMonster.genData("","MonsterProfile");
			ExchangeManager.appendFields( monsterData, EditMonster.genData("", "TrapProfile") );
			ExchangeManager.appendFields( monsterData, EditMonster.genData("", "BulletProfile"));
			for( i=0; i<monsterData.length; i++ )
				monsterFields.push( monsterData[i][ConfigPanel.kKEY] );
			
			var totalRow:int = 10;
			for each( level in chapter.levels )
			{
				totalRow +=2;
				for each( monster in level.monsters )
					totalRow ++;
			}
			
			sheet.resize( totalRow, monsterData.length + levelData.length );
		
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
			for each( level in chapter.levels )
			{
				var colInd:int = 0;
				for( i=0; i<levelFields.length; i++, colInd++ )
					sheet.setCell(rowInd, colInd, level[levelFields[i]]); 
				
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
					for( i=0; i<monsterFields.length; i++, nowInd++ )
					{
						if( monsterFields[i] in monster ) 
							sheet.setCell( rowInd, nowInd, JSON.stringify(monster[monsterFields[i]]) );					
					}
					rowInd ++;
				}
			}
			
			var xls:ExcelFile = new ExcelFile();
			xls.sheets.addItem( sheet );
			
			var fr:FileReference = new FileReference( );
			fr.save(xls.saveToByteArray(), chapter.id+".xls");
		}
	}
}