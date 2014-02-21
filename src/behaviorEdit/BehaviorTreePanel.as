package behaviorEdit
{
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.dns.AAAARecord;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.controls.Alert;
	import mx.controls.Tree;
	import mx.events.CloseEvent;
	
	import spark.components.Panel;
	import spark.components.TextInput;
	
	import manager.EventManager;
	
	public class BehaviorTreePanel extends Panel
	{
		private var controller:BTEditController;
		private var btTree:Tree;
		private var searchFrame:TextInput;
		
		public function BehaviorTreePanel(ctrl:BTEditController)
		{
			this.controller = ctrl;
			this.title = "行为库";
			this.x = 1000;
			this.addElement(this);
			
			searchFrame = new TextInput;
			searchFrame.prompt = "搜索";
			searchFrame.width = 150;
			searchFrame.height = 20;
			searchFrame.addEventListener(Event.CHANGE, onSearching);
			this.addElement(searchFrame);
			
			/*btTree = new Tree;
			btTree.enabled = true;
			btTree.labelField = "@label";
			btTree.percentWidth = 100;
			btTree.percentHeight = 100;
			btTree.showRoot = false;
			btTree.addEventListener(MouseEvent.CLICK, onBehaviorClick);
			btTree.y = 20;
			this.addElement(btTree);
			updateTree();
			
			var treeMenu:ContextMenu = new ContextMenu;
			var item0:ContextMenuItem = new ContextMenuItem("删除当前");
			item0.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onDeleteBT);
			treeMenu.addItem(item0);
			btTree.contextMenu = treeMenu;*/
			
			var tree:XMLDisplayer = new XMLDisplayer;
			tree.dataProvider = Data.getInstance().bh_xml;
			tree.labelField = "label";
			tree.width = 150;
			tree.x = 0;
			tree.y = 20;
			this.addElement(tree);
			tree.display();
			
			EventManager.getInstance().addEventListener(BehaviorEvent.BT_XML_APPEND, updateTree);
			EventManager.getInstance().addEventListener(BehaviorEvent.BT_ADDED, updateTree);
		}
		
		public function updateTree(e:BehaviorEvent = null):void
		{
			var content:String = searchFrame.text;
			var electData:Array = new Array;
			for(var b:String in Data.getInstance().bh_lib)
				if(b.search(content) == 0)
					electData.push(b);
			electData.sort();
			btTree.dataProvider = parse(electData);
		}
		
		private function parse(data:Array):XML
		{
			var xml:XML = <Root></Root>;
			for each(var b:* in data)
				xml.appendChild(new XML("<parm label='"+b+"'></parm>"));
			return xml;
		}
		
		private function onSearching(e:Event):void
		{
			updateTree();
		}
		
		private function onBehaviorClick(e:MouseEvent):void
		{
			var selectedNode:XML = (e.currentTarget as Tree).selectedItem as XML;
			if(selectedNode)
			{
				var label:String=selectedNode.@label;
				EventManager.getInstance().dispatchEvent(new BehaviorEvent(BehaviorEvent.CREATE_NEW_BT, label));
			}
		}
		
		private function onDeleteBT(e:ContextMenuEvent):void
		{
			if(btTree.selectedIndex >= 0)
				Alert.show("删除库行为会一并删除所有相关的行为，确定删除？", "tips", Alert.OK|Alert.CANCEL, this, onDeleteBtClose);
			else
				Alert.show("请先选择要删除的行为");
		}
		
		private function onDeleteBtClose(e:CloseEvent):void
		{
			if(e.detail == Alert.OK)
			{
				Data.getInstance().deleteBehaviors(btTree.selectedItem.@label);
				btTree.dataProvider = Data.getInstance().bh_xml;
				controller.getBTs().refresh();
				EventManager.getInstance().dispatchEvent(new BehaviorEvent(BehaviorEvent.BT_REMOVED));
			}
		}
		
	}
}