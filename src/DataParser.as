package
{
	public class DataParser
	{
		// 
		public function DataParser() {}
		
		// ---
		static public function genMonstersTable( chapters:Object ):Object
		{
			var ret:Object = {};
			
			for each( var chapter:Object in chapters )
			{
				var profiles:Object = chapter.levels;
				for( var lid:String in profiles )
				{
					for( var mid:String in profiles[lid].monsters )
					{
						ret[mid] = profiles[lid].monsters[mid];
					}
				}
			}
			return ret; 
		}
		
		static public function genLevel2MonsterTable( chapters:Object ):Object
		{
			var ret:Object = {};
			for each( var chapter:Object in chapters )
			{
				var profiles:Object = chapter.levels;
				for( var lid:String in profiles )
				{
					ret[lid] = profiles[lid].monsters;
				}
			}
			return ret;
		}
		
		static public function genLevelXML( levelProfiles:Object ):XML 
		{
			var profiles:Object = {};
			for each( var level:Object in levelProfiles)
			{
				if( !profiles.hasOwnProperty( level.chapter_id ) )
				{
					profiles[level.chapter_id] = {
						levels : [],
						chapter_name : level.chapter_name,
						chapter_id : level.chapter_id
					};
				}
				
				profiles[level.chapter_id].levels.push( level );
			}
			
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