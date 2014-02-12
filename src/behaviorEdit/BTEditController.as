package behaviorEdit
{
	import manager.EventManager;

	public class BTEditController
	{
		private var editTargetType:String = "";
		private var btArray:Array = null;
		
		public function BTEditController(type:String)
		{
			editTargetType = type;
			btArray = Data.getInstance().enemyBTData[editTargetType] as Array;
		}
		
		public function getBTs():Array
		{
			return btArray;
		}
		
		public function addBT(bName:String, data:Object):void
		{
			if(!Data.getInstance().behaviors.hasOwnProperty(bName))
				Data.getInstance().addBehaviors(bName, data);
			btArray.addItem(bName);
			Data.getInstance().saveEnemyBehaviorData();
			
			var evt:BehaviorEvent = new BehaviorEvent(BehaviorEvent.ADD_BT);
			evt.msg = bName;
			EventManager.getInstance().dispatchEvent(evt);
		}
		
		public function removeBTByIndex(index:int):void
		{
			if(index>=0 && index<btArray.length) 
			{
				btArray.removeItemAt(index);
				Data.getInstance().saveEnemyBehaviorData();
				var evt:BehaviorEvent = new BehaviorEvent(BehaviorEvent.REMOVE_BT);
				evt.msg = index;
				EventManager.getInstance().dispatchEvent(evt);
			}
			else
				trace("removeBT:index is out of range");
		}
		
		public function save(bName:String, data:Object):void
		{
			Data.getInstance().updateBehavior(bName, data);
		}
		
		
	}
}