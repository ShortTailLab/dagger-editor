package
{
	public class DataParser
	{
		// 
		public function DataParser() {}
		
		// ---
		static public function genMonstersTable( profiles:Object ):Object
		{
			var ret:Object = {};
			for each( var chapter:* in profiles )
			for each( var level:* in chapter.levels )
			for( var key:* in level.monsters )
				ret[key] = level.monsters[key];
			return ret;
		}
		
		static public function genLevel2MonsterTable( profiles:Object ):Object
		{
			var ret:Object = {};
			for each( var item:* in profiles )
			{
				var kids:Object = item.levels;
				for each( var l:* in kids )
				{ 
					ret[l.level_id] = l.monsters;
				}
			}
			
			return ret;
		}
		
		static public function genLevelIdList( profiles:Object ):Array
		{
			var ret:Array = [];
			for each( var item:* in profiles )
			{
				var kids:Object = item.levels;
				for each( var l:* in kids )
				ret.push(l.level_id);	
			}
			return ret;
		}
		
		static public function genLevelXML( profiles:Object ):XML 
		{
			var ret:XML = <root></root>;
			for each( var item:* in profiles )
			{
				var kids:Object = item.levels;
				
				var lastNode:XML = new XML("<node label='" + item.chapter_name + "'></node>")
				ret.appendChild(lastNode);
				
				var levelList:Array = new Array;
				
				for each(var l:Object in kids)
				levelList.push(l);
				
				// sort by level id
				levelList.sortOn("level_id");
				
				for(var i:int=0; i<levelList.length; i++)
				{
					var level:Object = levelList[i];
					
					var node:XML = new XML("<level></level>");
					node.@label = level.level_name;
					node.@level_id = level.level_id;
					
					lastNode.appendChild(node);
				}
			}
			return ret;
		}
		
	}
}