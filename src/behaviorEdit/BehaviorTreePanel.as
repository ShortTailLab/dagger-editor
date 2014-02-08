package behaviorEdit
{
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.controls.Alert;
	import mx.controls.Tree;
	import mx.events.CloseEvent;
	
	import spark.components.Panel;
	
	public class BehaviorTreePanel extends Panel
	{
		private var parPanel:BTEditPanel = null;
		private var btTree:Tree;
		
		public function BehaviorTreePanel(par:BTEditPanel)
		{
			this.parPanel = par;
			this.title = "行为库";
			this.x = 1000;
			this.addElement(this);
			btTree = new Tree;
			btTree.dataProvider = Data.getInstance().behaviorsXML;
			btTree.enabled = true;
			btTree.labelField = "@label";
			btTree.percentWidth = 100;
			btTree.percentHeight = 100;
			btTree.showRoot = false;
			btTree.addEventListener(MouseEvent.CLICK, onBehaviorClick);
			this.addElement(btTree);
			
			var treeMenu:ContextMenu = new ContextMenu;
			var item0:ContextMenuItem = new ContextMenuItem("删除当前");
			item0.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onDeleteBT);
			treeMenu.addItem(item0);
			btTree.contextMenu = treeMenu;
		}
		
		public function updateTree():void
		{
			btTree.dataProvider = Data.getInstance().behaviorsXML;
		}
		
		private function onBehaviorClick(e:MouseEvent):void
		{
			var selectedNode:XML = (e.currentTarget as Tree).selectedItem as XML;
			var label:String=selectedNode.@label;
			parPanel.userPanel.setNewBt(label);
		}
		
		private function onDeleteBT(e:ContextMenuEvent):void
		{
			if(btTree.selectedIndex >= 0)
				Alert.show("删除库行为会一并删除所有相关的行为，确定删除？", "tips", Alert.OK|Alert.CANCEL, this, onDeleteBtClose);
			
		}
		
		private function onDeleteBtClose(e:CloseEvent):void
		{
			if(e.detail == Alert.OK)
			{
				Data.getInstance().deleteBehaviors(btTree.selectedItem.@label);
				btTree.dataProvider = Data.getInstance().behaviorsXML;
				parPanel.btArray.refresh();
			}
		}
		
	}
}