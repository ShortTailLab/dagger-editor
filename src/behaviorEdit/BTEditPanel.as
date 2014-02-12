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
	import mx.controls.Tree;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
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
	import manager.MsgInform;
	
	public class BTEditPanel extends TitleWindow
	{
		public var currNode:BNode = null;
		public var userPanel:UserPanel = null;
		private var behaviorsPanel:BehaviorTreePanel;
		private var grabLayer:UIComponent = null;
		public var editTargetType:String;
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
			editTargetType = target.type;
			
			behaviorsPanel = new BehaviorTreePanel(this);
			behaviorsPanel.width = 100;
			behaviorsPanel.percentHeight = 100;
			behaviorsPanel.x = 1000;
			this.addElement(behaviorsPanel);
			
			userPanel = new UserPanel(this);
			this.addElement(userPanel);
			
			if(!Data.getInstance().enemyBTData.hasOwnProperty(editTargetType))
				Data.getInstance().enemyBTData[editTargetType] = new Array;
			btArray = new ArrayCollection(Data.getInstance().enemyBTData[editTargetType] as Array);
			
			_state = btArray.length > 0 ? BTEditState.EXEC_BT : BTEditState.NEW_BT;
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
			onChangeBt();
			
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
			if(value == BTEditState.NEW_BT)
			{
				btBar.alpha = 0.3;
				prevBTName = "";
			}
			else
			{
				btBar.alpha = 1;
			}
			_state = value;
		}
		
		public function setStateToNew():void
		{
			if(state != BTEditState.NEW_BT)
				editView.clear();
			state = BTEditState.NEW_BT;
		}
		
		public function setStateToExec():void
		{
			if(state == BTEditState.NEW_BT)
			{
				btBar.selectedIndex = 0;
			}
			state = BTEditState.EXEC_BT;
		}

		
		public function setCurrBehavior(name:String):void
		{
			if(Data.getInstance().behaviors.hasOwnProperty(name))
			{
				if(prevBTName != "" && prevBTName != name)
				{
					Data.getInstance().updateBehavior(prevBTName, editView.export());
				}
				editView.init(Data.getInstance().behaviors[name]);
				prevBTName = name;
			}
			else
			{
				editView.clear();
				trace("setCurrBehavior:"+name+"不存在");
			}
		}
		
		public function addBT(bName:String):void
		{
			var data:Object = editView.export();
			if(!Data.getInstance().behaviors.hasOwnProperty(bName))
				Data.getInstance().addBehaviors(bName, data);
			btArray.addItem(bName);
			Data.getInstance().saveEnemyBehaviorData();
			btBar.selectedItem = bName;
			this.setCurrBehavior(bName);
			onChangeBt();
		}
		
		public function removeBT(index:int):void
		{
			if(index>=0 && index<btArray.length) 
			{
				btArray.removeItemAt(index);
				Data.getInstance().saveEnemyBehaviorData();
				var bName:String = "";
				if(btArray.length > 0)
				{
					var index2:int = Math.max(0, index-1);
					btBar.selectedIndex = index2;
					bName = btArray[index2];
				}
				else
					this.setStateToNew();
				setCurrBehavior(bName);
				onChangeBt();
			}
			else
				trace("removeBT:index is out of range");
		}
		
		private var newBtn:Button = null;
		private function onChangeBt():void
		{
			if(btArray.length == 0 && !newBtn)
			{
				newBtn = new Button;
				newBtn.label = "+";
				newBtn.width = 30;
				newBtn.height = 30;
				newBtn.x = 140;
				newBtn.y = 5;
				newBtn.addEventListener(MouseEvent.CLICK, onNewBtnClick);
				this.addElement(newBtn);
			}
			else if(btArray.length > 0 && newBtn)
			{
				newBtn.removeEventListener(MouseEvent.CLICK, onNewBtnClick);
				this.removeElement(newBtn);
				newBtn = null;
			}
		}
		
		private function onNewBtnClick(e:MouseEvent):void
		{
			userPanel.onNewBT(null);
		}
		
		
		public function save():void
		{
			if(state == BTEditState.EXEC_BT && btBar.selectedIndex >= 0)
			{
				if(Data.getInstance().behaviors.hasOwnProperty(btBar.selectedItem))
				{
					Data.getInstance().updateBehavior(btBar.selectedItem, editView.export())
					MsgInform.shared().show(this, "保存成功!");
				}
				else
					MsgInform.shared().show(this, "行为名不存在!");
			}
			else if(state == BTEditState.NEW_BT)
			{
				if(userPanel.isEditing())
					userPanel.onNewConfirmClick(null);
				else
				{
					MsgInform.shared().show(this, "请先输入行为名!");
					userPanel.onNewBT(null);
				}
			}
		}
		
		private function onClickBt(e:MouseEvent):void
		{
			if(state == BTEditState.EXEC_BT)
			{
				this.setCurrBehavior(btBar.selectedItem);
			}
			else if(state == BTEditState.NEW_BT)
			{
				MsgInform.shared().show(this, "新建行为未保存!");
			}
		}
		
		private function onDeleteEnemyBT(e:ContextMenuEvent):void
		{
			removeBT(btBar.selectedIndex);
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
			
			var msg:String = "";
			for each(var bname:String in btArray)
				if(Utils.genBTreeJS(Data.getInstance().behaviors[bname]) == "")
				{
					trace(bname);
					msg += bname + " ";
				}
			if(msg.length > 0)
			{
				Alert.show("行为"+msg+"不合法，请检查！");
			}
		}
	}
}