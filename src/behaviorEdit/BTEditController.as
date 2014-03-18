package behaviorEdit
{
	import mx.collections.ArrayCollection;
	
	import manager.EventManager;
	import manager.MsgInform;

	public class BTEditController
	{
		public var editTargetType:String = "";
		public var isCreatingNew:Boolean = false; 
		public var currEditBehavior:String = "";
		
		private var btArray:ArrayCollection;
		private var parPanel:BTEditPanel = null;
		
		public function BTEditController(par:BTEditPanel, type:String)
		{
			parPanel = par;
			editTargetType = type;
			
			btArray = new ArrayCollection(Data.getInstance().getBehaviorById( editTargetType ) as Array);
			
			EventManager.getInstance().addEventListener(BehaviorEvent.CREATE_NEW_BT, onNewBT);
			EventManager.getInstance().addEventListener(BehaviorEvent.CREATE_BT_DONE, onCreateDone);
			EventManager.getInstance().addEventListener(BehaviorEvent.CREATE_BT_CANCEL, onCreateCancel);
		}
		
		public function getBTs():ArrayCollection
		{
			return btArray;
		}
		
		public function addBT(bName:String):void
		{
			var data:Object = parPanel.editView.export();
			
			if(!Data.getInstance().getBehaviorById(bName))
				Data.getInstance().updateBehaviorSetById(bName, data);
			
			btArray.addItem(bName);
			
			var evt:BehaviorEvent = new BehaviorEvent(BehaviorEvent.BT_ADDED, bName);
			EventManager.getInstance().dispatchEvent(evt);
		}
		
		public function removeBTByIndex(index:int):void
		{
			btArray.removeItemAt(index);
			var evt:BehaviorEvent = new BehaviorEvent(BehaviorEvent.BT_REMOVED, index);
			EventManager.getInstance().dispatchEvent(evt);
			
			if(btArray.length > 0)
			{
				var currIndex = Math.max(index-1, 0);
				setCurrEditBehavior(btArray[currIndex]);
			}
			else
				setCurrEditBehavior("");
			
		}
		
		public function renameBTbyIndex(index:int, bName:String):void
		{
			var prevName:String = btArray[index];
			
			var data = Data.getInstance().behaviorSet[prevName];
			delete Data.getInstance().behaviorSet[prevName];
			Data.getInstance().updateBehaviorSetById( bName, data );
			
			btArray.setItemAt(bName, index);
		}
		
		public function saveSelectItem():void
		{
			if(!isCreatingNew)
			{
				if(btArray.length > 0)
				{
					save(parPanel.bar.selectedItem, parPanel.editView.export());
					MsgInform.shared().show(parPanel, "保存成功!");
				}
				else
				{
					EventManager.getInstance().dispatchEvent(new BehaviorEvent(BehaviorEvent.CREATE_NEW_BT));
					MsgInform.shared().show(parPanel, "请先输入行为名!");
				}
			}
			else
			{
				MsgInform.shared().show(parPanel, "请先输入行为名!");
			}
		}
		
		public function save(bName:String, data:Object):void
		{
			Data.getInstance().updateBehaviorSetById(bName, data);
		}
		
		public function setCurrEditBehavior(bName:String):void
		{
			if(currEditBehavior != "" && bName != currEditBehavior)
			{
				save(currEditBehavior, parPanel.editView.export());
			}
			currEditBehavior = bName;
			if(currEditBehavior != "")
			{
				parPanel.editView.init( Data.getInstance().getBehaviorById(bName) );
				parPanel.bar.selectedItem = currEditBehavior;
			}
			else
				parPanel.editView.clear();
		}
		
		private function onNewBT(e:BehaviorEvent):void
		{
			if(e.msg != "")
			{
				currEditBehavior = "";
				parPanel.editView.init( Data.getInstance().getBehaviorById(e.msg) );
			}
			else if(currEditBehavior != "")
				this.setCurrEditBehavior("");
				
			isCreatingNew = true;
		}
		
		private function onCreateDone(e:BehaviorEvent):void
		{
			isCreatingNew = false;
			setCurrEditBehavior(e.msg);
		}
		
		private function onCreateCancel(e:BehaviorEvent):void
		{
			isCreatingNew = false;
			if(btArray.length > 0)
				setCurrEditBehavior(btArray[0]);
		}
		
	}
}