package behaviorEdit
{
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Tree;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.HScrollBar;
	import spark.components.Panel;
	import spark.components.TabBar;
	import spark.components.TextInput;
	import spark.components.TitleWindow;
	import spark.components.VGroup;
	import spark.components.VScrollBar;
	import editEntity.MatSprite;
	
	import manager.EventManager;
	
	public class BTEditPanel extends TitleWindow
	{
		public var currNode:BNode = null;
		public var userPanel:UserPanel = null;
		private var behaviorsPanel:BehaviorTreePanel;
		private var grabLayer:UIComponent = null;
		public var editType:String;
		public var editView:BTEditView;
		private var currBName:String = "";
		private var currBData:Object = null;
		public var btArray:ArrayCollection = null;
		private var newBtInput:TextInput = null;
		private var btBar:TabBar = null;
		private var deleteBtn:Button;
		
		private var bnameLabel:TextField = null;
		private var state_undefine:String = "未命名";
		//this indicate the creating new bt or edit existed bt state.
		private var _state:String = BTEditState.EXEC_BT;
		private var prevBTName:String = "";
		
		public function BTEditPanel(target:MatSprite)
		{
			BNodeFactory.numCount = 0;
			this.title = "行为编辑";
			this.width = 1100;
			this.height = 800;
			this.setStyle("backgroundColor", 0xEEE8AA);
			editType = target.type;
			
			behaviorsPanel = new BehaviorTreePanel(this);
			behaviorsPanel.width = 100;
			behaviorsPanel.percentHeight = 100;
			behaviorsPanel.x = 1000;
			this.addElement(behaviorsPanel);
			
			userPanel = new UserPanel(this);
			this.addElement(userPanel);
			
			btArray = new ArrayCollection(Data.getInstance().enemyBTData[editType] as Array);
			btBar = new TabBar(); 
			//btBar.setStyle("chromeColor", "#EEE8AA"); 
			btBar.height = 40;
			btBar.x = 120;
			btBar.dataProvider = btArray;
			btBar.selectedIndex = 0;
			//btBar.addEventListener(IndexChangeEvent.CHANGE, onChangeBt);
			btBar.addEventListener(MouseEvent.CLICK, onClickBt);
			this.addElement(btBar);
			
			var menu:ContextMenu = new ContextMenu;
			var item2:ContextMenuItem = new ContextMenuItem("重命名");
			item2.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onRenameBT);
			var item3:ContextMenuItem = new ContextMenuItem("删除");
			item3.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onDeleteEnemyBT);
			menu.addItem(item2);
			menu.addItem(item3);
			btBar.contextMenu = menu;
			
			var editGroup:HGroup = new HGroup();
			editGroup.y = 40;
			editGroup.x = 120;
			editGroup.width = 880;
			editGroup.percentHeight = 100;
			var group:Group = new Group();
			group.clipAndEnableScrolling = true;
			group.percentWidth = 100;
			group.percentHeight = 100;
			editView = new BTEditView(this);
			group.addElement(editView);
			var vGroup:VGroup = new VGroup;
			vGroup.percentWidth = 100;
			vGroup.percentHeight = 100;
			vGroup.addElement(group);
			var hscrollbar:HScrollBar = new HScrollBar;
			hscrollbar.percentWidth = 100;
			hscrollbar.viewport = group;
			vGroup.addElement(hscrollbar);
			editGroup.addElement(vGroup);
			var vscrollbar:VScrollBar = new VScrollBar();
			vscrollbar.percentHeight = 100;
			vscrollbar.viewport = group;
			editGroup.addElement(vscrollbar);
			this.addElement(editGroup);
			
			//this used to add the dragging node.
			grabLayer = new UIComponent;
			this.addElement(grabLayer);
			
			this.setCurrBehavior(btBar.selectedItem);
			
			this.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.addEventListener(CloseEvent.CLOSE, onClose);
		}
		
		public function get state():String
		{
			return _state;
		}

		public function set state(value:String):void
		{
			_state = value;
			prevBTName = "";
			if(_state == BTEditState.NEW_BT)
				btBar.alpha = 0.3;
			else
				btBar.alpha = 1;
		}

		public function setCurrBehavior(name:String):void
		{
			if(Data.getInstance().behaviors.hasOwnProperty(name))
			{
				if(prevBTName != "" && prevBTName != name)
					Data.getInstance().updateBehavior(prevBTName, editView.export());
				editView.init(Data.getInstance().behaviors[name]);
				prevBTName = name;
			}
			else
			{
				editView.clear();
				trace("setCurrBehavior:"+name+"不存在");
			}
		}
		
		public function addNewBT(bName:String):void
		{
			var data:Object = editView.export();
			if(!Data.getInstance().behaviors.hasOwnProperty(bName))
				Data.getInstance().addBehaviors(bName, data);
			btArray.addItem(bName);
			Data.getInstance().saveEnemyBehaviorData();
			btBar.selectedItem = bName;
			this.setCurrBehavior(bName);
		}
		
		public function save():void
		{
			if(btBar.selectedIndex >= 0)
				Data.getInstance().updateBehavior(btBar.selectedItem, editView.export());
			else
				trace("undefine bt");
		}
		
		private function onClickBt(e:MouseEvent):void
		{
			if(state == BTEditState.EXEC_BT)
			{
				this.setCurrBehavior(btBar.selectedItem);
			}
			else if(state == BTEditState.NEW_BT)
			{
				Alert.show("请先完成新建行为");
			}
		}
		
		private function onDeleteEnemyBT(e:ContextMenuEvent):void
		{
			var currBName:String = btBar.selectedItem;
			btArray.removeItemAt(btBar.selectedIndex);
			Data.getInstance().saveEnemyBehaviorData();
		}
		
		private function onRenameBT(e:ContextMenuEvent):void
		{
			var window:RenamePanel = new RenamePanel;
			window.addEventListener(MsgEvent.RENAME_LEVEL, onRenameConfirm);
			
			PopUpManager.addPopUp(window, this, true);
			PopUpManager.centerPopUp(window);
		}
		
		private function onRenameConfirm(e:MsgEvent):void
		{
			if(e.hintMsg.length > 0)
			{
				Data.getInstance().renameBehavior(btBar.selectedItem, e.hintMsg);
				btArray.setItemAt(e.hintMsg, btBar.selectedIndex);
				behaviorsPanel.updateTree();
				Alert.okLabel = "确定";
			}
			else
				Alert.show("命名不能未空");
		}
		
		private function onMouseMove(e:MouseEvent):void
		{
			if(currNode)
			{
				currNode.x = this.mouseX-10;
				currNode.y = this.mouseY-15;
			}
			EventManager.getInstance().dispatchEvent(e);
		}
		
		private function onMouseUp(e:MouseEvent):void
		{
			if(currNode)
			{
				grabLayer.removeChild(currNode);
				currNode = null;
			}
			
			EventManager.getInstance().dispatchEvent(e);
		}
		
		
		public function setCurrSelectNode(nodeType:String):void
		{
			currNode = BNodeFactory.createBNode(nodeType);
			currNode.x = this.mouseX-10;
			currNode.y = this.mouseY-15;
			currNode.alpha = 0.5;
			grabLayer.addChild(currNode);
		}
		
		private function onClose(e:CloseEvent):void
		{
			save();
			editView.remove();
			PopUpManager.removePopUp(this);
		}
	}
}