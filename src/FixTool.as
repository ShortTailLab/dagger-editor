package
{
	public class FixTool
	{
		public function FixTool()
		{
			trace("checking....");
			for(var bName in Data.getInstance().behaviors)
			{
				trace(bName);
				checkBNode(Data.getInstance().behaviors[bName]);
			}
			
			
			trace("checking data");
			var missingData:Object = new Object;
			for(var i:int = 0; i < Data.getInstance().displayData.length; i++)
			{
				if(i >= 5)
				{
					missingData = new Object;
					trace(Data.getInstance().displayData[i].levelName);
					for each(var eData in Data.getInstance().displayData[i].data as Array)
					{
						if(!Data.getInstance().enemyData.hasOwnProperty(eData.type) && !missingData.hasOwnProperty(eData.type))
						{
							trace(eData.type);
							missingData[eData.type] = 1;
						}
					}
				}
			}
		}
		
		private function checkBNode(node:Object):void
		{
			if(node.type == "执行")
			{
				var execData = node.data;
				for each(var piece in execData.parm as Array)
				{
					if(piece.name == "addr" && !Data.getInstance().enemyData.hasOwnProperty(piece.value))
						trace(execData.execType+":"+piece.value);
				}
			}
			
			for each(var node in node.children as Array)
			{
				checkBNode(node);
			}
		}
	}
}