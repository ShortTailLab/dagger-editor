package behaviorEdit
{
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.controls.Alert;
	
	import spark.components.Button;
	import spark.components.HGroup;
	import spark.components.TabBar;
	
	public class BehaviorBar extends HGroup
	{
		private var btBar:TabBar = null;
		private var controller:BTEditController = null;
		private var newBtn:Button;
		
		private var mMenu:ContextMenu = null;
		public var mTabBar:TabBar = null;
		
		public function BehaviorBar(_controller:BTEditController)
		{
			controller = _controller;
			
			this.height = 35;
			this.percentWidth = 100;
			
			mTabBar = new TabBar();	
			mTabBar.dataProvider = controller.openedBehaviors;
			mTabBar.selectedIndex = 0;
			mTabBar.addEventListener(MouseEvent.CLICK, onClickTabItem);
			this.addElement(mTabBar);
			
			var buttonGroup:HGroup = new HGroup();
			buttonGroup.width = 400;
			buttonGroup.horizontalAlign = "right";
			this.addElement(buttonGroup);
			
			var saveButton:Button = new Button();
			saveButton.label = "保存当前";
			saveButton.addEventListener(MouseEvent.CLICK, onSaveClick);
			buttonGroup.addElement(saveButton);
			
			var newBehaviorButton:Button = new Button();
			newBehaviorButton.label = "新行为";
			newBehaviorButton.addEventListener(MouseEvent.CLICK, onNewBehaviorClick);
			buttonGroup.addElement(newBehaviorButton);
			
			var genBehaviorButton:Button = new Button();
			genBehaviorButton.label = "生成代码";
			genBehaviorButton.addEventListener(MouseEvent.CLICK, onGenBehaviorClick);
			buttonGroup.addElement(genBehaviorButton);
			
			mMenu = new ContextMenu;
			
			var item2:ContextMenuItem = new ContextMenuItem("重命名");
			item2.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onRenameTab);
			mMenu.addItem(item2);
			
			var item3:ContextMenuItem = new ContextMenuItem("关闭");
			item3.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onCloseTab);
			mMenu.addItem(item3);
			
			mTabBar.contextMenu = mMenu;
		}

		private function onNewBehaviorClick(e:MouseEvent):void
		{
			var randUint:uint = uint(Math.random() * uint.MAX_VALUE);
			var name:String = "新行为" + randUint.toString();
			controller.createNewBehavior(name);
		}
		
		private function onSaveClick(e:MouseEvent):void
		{
			var name:String = mTabBar.selectedItem;
			if(name)
				controller.saveBehavior(name);
		}
		
		private function onGenBehaviorClick(e:MouseEvent):void
		{
			var rawString:String = Utils.genBTreeJS(Data.getInstance().getBehaviorById(controller.selectedBehavior) );
			var x:Object = {};
			x.a = rawString;
			var jsonString:String = JSON.stringify(x, null, "\t");
			trace(jsonString);
		}

		private function onClickTabItem(e:MouseEvent):void
		{
			var name:String = mTabBar.selectedItem;
			controller.openBehavior(name);
		}
		
		private function onCloseTab(e:ContextMenuEvent):void
		{
			var name:String = mTabBar.selectedItem;
			controller.closeBehavior(name);
			
			if(controller.openedBehaviors.length)
				controller.openBehavior(controller.openedBehaviors[0]);
		}
		
		private function onRenameTab(e:ContextMenuEvent):void
		{
			var fromName:String = controller.selectedBehavior;
			Utils.makeRenamePanel( function( toName:String ):void 
			{
				if( toName.length > 0 )
					controller.renameBehavior(fromName, toName); 
				else 
					Alert.show("【错误】命名不能为空");
			}, controller.editPanel);
		}
	}
}