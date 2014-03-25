package behaviorEdit
{
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	
	import manager.EventManager;
	import manager.MsgInform;

	public class BTEditController
	{
		public var editTargetType:String = "";
		
		private var mOpenedBehaviors: ArrayCollection;
		private var mSelectedBehavior:String = "";
		private var mEditPanel:BTEditPanel = null;
		
		public function BTEditController(par:BTEditPanel, type:String)
		{
			mEditPanel = par;
			editTargetType = type;
			
			// open all behaviors related to current unit, this should only open 1 behavior
			mOpenedBehaviors = new ArrayCollection(
				Data.getInstance().getEnemyBehaviorsById( 
					Runtime.getInstance().currentLevelID, editTargetType 
				) as Array
			);
		}
		
		public function get editPanel(): BTEditPanel
		{
			return mEditPanel;
		}
		
		public function get selectedBehavior():String
		{
			return mSelectedBehavior;
		}
		
		public function get openedBehaviors():ArrayCollection
		{
			return mOpenedBehaviors;
		}
		
		public function selectDefaultBehavior()
		{
			if(mOpenedBehaviors.length)
			{
				mSelectedBehavior = mOpenedBehaviors[0];
				mEditPanel.bar.mTabBar.selectedItem = mSelectedBehavior;
			}
			else
				mEditPanel.userPanel.behaviorLabel.text = "<空行为>";
		}
		
		public function getUnitBehaviorName():String
		{
			var list:Array = Data.getInstance().getEnemyBehaviorsById( 
				Runtime.getInstance().currentLevelID, editTargetType 
			) as Array;
			return list.length ? list[0] : "";
		}
		
		public function setUnitBehavior(name:String)
		{
			var val = name != "" ? [name] : [];
			Data.getInstance().updateEnemyBehaviorsById( 
				Runtime.getInstance().currentLevelID, editTargetType, val 
			);
			if(name)
				mEditPanel.userPanel.behaviorLabel.text = name;
			else
				mEditPanel.userPanel.behaviorLabel.text = "<空行为>";
		}
		
		public function createNewBehavior(name:String):void
		{
			if(Data.getInstance().getBehaviorById(name))
			{
				Alert.show("同名行为已经存在，无法创建");
				return;
			}
				
			// create empty behavior
			var data:Object = {};
			Data.getInstance().updateBehaviorSetById(name, data);

			openBehavior(name);
			
			mEditPanel.behaviorsPanel.refreshBehaviorData();
		}
		
		public function openBehavior(name:String):void
		{
			if(name && name != "")
			{
				// open tree in edit view
				var btToOpen = Data.getInstance().getBehaviorById(name)
				mEditPanel.editView.init(btToOpen);
							
				// tab controller should update itself accordingly
				if(mOpenedBehaviors.getItemIndex(name) == -1)
					mOpenedBehaviors.addItem(name);
			
				mSelectedBehavior = name;
			}
		}
		
		public function saveBehavior(name:String):void
		{
			if(name && name != "")
			{
				var currBehavior:* = mEditPanel.editView.export();
				Data.getInstance().updateBehaviorSetById(name, currBehavior);
				MsgInform.shared().show(mEditPanel, "保存成功: " + name);
			}
			else
				MsgInform.shared().show(mEditPanel, "行为名不能为空!");
		}
		
		public function closeBehavior(name:String):void
		{
			var index:int = mOpenedBehaviors.getItemIndex(name);
			if(index != -1)
			{
				mOpenedBehaviors.removeItemAt(index);
				mEditPanel.editView.clear();
			}
		}

		public function removeBehavior(name:String):void
		{	
			// close its tab if openned
			closeBehavior(name);
			
			// clear current unit's behavior if it's what's being removed
			if(getUnitBehaviorName() == name)
				setUnitBehavior("");
			
			// find all instances using the behavior and remove the references
			var enemies:Array = Data.getInstance().findEnemiesByBehavior( 
				Runtime.getInstance().currentLevelID,
				name
			);
			
			for(var i:int=0; i<enemies.length; i++)
			{				
				Data.getInstance().updateEnemyBehaviorsById( 
					Runtime.getInstance().currentLevelID, enemies[i], [] 
				);
			}
			
			// remove it directly from data
			Data.getInstance().eraseBehaviorById(name);
			
			// update tree view
			mEditPanel.behaviorsPanel.refreshBehaviorData();
		}
		
		public function renameBehavior(fromName:String, toName:String):void
		{
			if(fromName == toName)
				return;
			
			if(fromName == "" || toName == "")
			{
				Alert.show("行为名不能为空.");
				return;
			}
			
			if(Data.getInstance().getBehaviorById(toName))
			{
				Alert.show("行为名已经存在，无法改名为 " + toName);
				return;
			}
			
			// if behavior opened, close it
			closeBehavior(fromName);
			
			// save with toName first
			var behaviorData = Data.getInstance().getBehaviorById(fromName);
			Data.getInstance().updateBehaviorSetById(toName, behaviorData);
			
			setUnitBehavior(toName);
			
			// find all instances using the behavior
			var enemies:Array = Data.getInstance().findEnemiesByBehavior( 
				Runtime.getInstance().currentLevelID,
				fromName
			);
			
			// change references to using new names
			for(var i:int=0; i<enemies.length; i++)
			{				
				Data.getInstance().updateEnemyBehaviorsById( 
					Runtime.getInstance().currentLevelID, enemies[i], [toName] 
				);
			}
			
			// remove old behavior
			removeBehavior(fromName);
			
			// reopen the toName behavior
			openBehavior(toName);
		}
	}
}