package behaviorEdit
{
	import com.montage.controls.IE7TabBar;
	
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
	import mx.events.ItemClickEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.ComboBox;
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.HScrollBar;
	import spark.components.Panel;
	import spark.components.TabBar;
	import spark.components.TextInput;
	import spark.components.TitleWindow;
	import spark.components.VGroup;
	import spark.components.VScrollBar;
	import spark.events.IndexChangeEvent;
	
	import editEntity.EditBase;
	import editEntity.MatFactory;
	import editEntity.MatSprite;
	
	import manager.EventManager;
	
	public class BTEditPanel extends TitleWindow
	{
		public var currNode:BNode = null;
		private var btnsView:UIComponent = null;
		private var grabLayer:UIComponent = null;
		private var editType:String;
		private var editView:BTEditView;
		private var currBName:String = "";
		private var currBData:Object = null;
		private var btArray:ArrayCollection = null;
		private var newBtInput:TextInput = null;
		private var btBar:TabBar = null;
		private var newBtn:Button;
		private var newConfirmBtn:Button;
		private var deleteBtn:Button;
		private var btTree:Tree;
		
		private var bnameLabel:TextField = null;
		private var state_undefine:String = "未命名";
		
		public function BTEditPanel(target:MatSprite)
		{
			BNodeFactory.numCount = 0;
			this.title = "行为编辑";
			this.width = 1100;
			this.height = 800;
			this.setStyle("backgroundColor", 0xEEE8AA);
			editType = target.type;
			
			
			
			var behaviorsPanel:Panel = new Panel;
			behaviorsPanel.title = "行为库";
			behaviorsPanel.width = 100;
			behaviorsPanel.percentHeight = 100;
			behaviorsPanel.x = 1000;
			this.addElement(behaviorsPanel);
			btTree = new Tree;
			btTree.dataProvider = Data.getInstance().behaviorsXML;
			btTree.enabled = true;
			btTree.labelField = "@label";
			btTree.percentWidth = 100;
			btTree.percentHeight = 100;
			btTree.showRoot = false;
			btTree.addEventListener(MouseEvent.CLICK, onBehaviorClick);
			behaviorsPanel.addElement(btTree);
			
			var treeMenu:ContextMenu = new ContextMenu;
			var item0:ContextMenuItem = new ContextMenuItem("删除当前");
			item0.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onDeleteBT);
			treeMenu.addItem(item0);
			btTree.contextMenu = treeMenu;
			
			var btnsPanel:Panel = new Panel;
			btnsPanel.title = "类型";
			btnsPanel.width = 120;
			btnsPanel.percentHeight = 100;
			btnsView = new UIComponent;
			btnsPanel.addElement(btnsView);
			this.addElement(btnsPanel);
			
			newBtn = new Button;
			newBtn.label = "添加行为";
			newBtn.width = 80;
			newBtn.height = 30;
			newBtn.x = 20;
			newBtn.y = 150;
			newBtn.addEventListener(MouseEvent.CLICK, onNewBT);
			btnsView.addChild(newBtn);
			
			
			var icon:EditBase = new MatSprite(null, editType, 100, 70);
			icon.x = 60;
			icon.y = 110;
			btnsView.addChild(icon);
			
			var btypes:Array = [BType.BTYPE_EXEC, BType.BTYPE_SEQ, BType.BTYPE_SEL,
								BType.BTYPE_PAR, BType.BTYPE_COND, BType.BTYPE_LOOP];
			var node:BNode;
			for(var i:int = 0; i < btypes.length; i++)
			{
				node = BNodeFactory.createBNode(btypes[i]);
				node.x = 20;
				node.y = 280+50*i;
				node.addEventListener(MouseEvent.MOUSE_DOWN, onNodeMouseDown);
				btnsView.addChild(node);
			}
			
			var saveBtn:Button = new Button;
			saveBtn.label = "保存";
			saveBtn.width = 80;
			saveBtn.height = 30;
			saveBtn.x = 20;
			saveBtn.y = node.y + 80;
			saveBtn.addEventListener(MouseEvent.CLICK, onSave);
			btnsView.addChild(saveBtn);
			
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
			
			
			grabLayer = new UIComponent;
			this.addElement(grabLayer);
			
			this.setCurrBehavior(btBar.selectedItem);
			
			this.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.addEventListener(CloseEvent.CLOSE, onClose);
		}
		
		public function setCurrBehavior(name:String):void
		{
			if(Data.getInstance().behaviors.hasOwnProperty(name))
			{
				editView.init(Data.getInstance().behaviors[name]);
			}
			else
				trace("setCurrBehavior:"+name+"不存在");
		}
		
		private function onNewBT(e:MouseEvent):void
		{
			editView.clear();
			
			newBtInput = new TextInput;
			newBtInput.width = 100;
			newBtInput.height = 30;
			newBtInput.x = 10;
			newBtInput.y = 190;
			newBtInput.prompt = "输入行为名";
			newBtInput.addEventListener(FlexEvent.ENTER, onEnterNewBt);
			btnsView.addChild(newBtInput);
			
			newConfirmBtn = new Button;
			newConfirmBtn.label = "确定";
			newConfirmBtn.width = 50;
			newConfirmBtn.height = 30;
			newConfirmBtn.x = 10;
			newConfirmBtn.y = 225;
			newConfirmBtn.addEventListener(MouseEvent.CLICK, onNewConfirmClick);
			btnsView.addChild(newConfirmBtn);
		}
		
		private var prevIndex:int = 0;
		private function onClickBt(e:MouseEvent):void
		{
			//Data.getInstance().updateBehavior(btArray[prevIndex], editView.export());
			this.setCurrBehavior(btBar.selectedItem);
			//prevIndex = btBar.selectedIndex;
		}
		
		private function onDeleteEnemyBT(e:ContextMenuEvent):void
		{
			var currBName:String = btBar.selectedItem;
			btArray.removeItemAt(btBar.selectedIndex);
			Data.getInstance().saveEnemyBehaviorData();
		}
		
		private function onDeleteBT(e:ContextMenuEvent):void
		{
			Alert.show("删除库行为会一并删除所有相关的行为，确定删除？", "tips", Alert.OK|Alert.CANCEL, this, onDeleteBtClose);
			
		}
		
		private function onDeleteBtClose(e:CloseEvent):void
		{
			if(e.detail == Alert.OK)
			{
				Data.getInstance().deleteBehaviors(btTree.selectedItem.@label);
				btTree.dataProvider = Data.getInstance().behaviorsXML;
				btArray.refresh();
			}
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
				Alert.okLabel = "确定";
			}
			else
				Alert.show("命名不能未空");
		}
		
		private function onNewConfirmClick(e:MouseEvent):void
		{
			onEnterNewBt(null);
		}
		
		private function onEnterNewBt(e:FlexEvent):void
		{
			var bName:String = newBtInput.text;
			if(newBtInput.text.length == 0)
			{
				Alert.show("行为名不能为空！");
				return;
			}
			if(Data.getInstance().enemyContainsBehavior(editType, newBtInput.text))
			{
				Alert.show("该行为已经存在！");
				return;
			}
			
			var data:Object = editView.export();
			if(!Data.getInstance().behaviors.hasOwnProperty(bName))
				Data.getInstance().addBehaviors(bName, data);
			btArray.addItem(bName);
			btBar.selectedIndex = btArray.length-1;
			Data.getInstance().saveEnemyBehaviorData();
			
			newBtInput.removeEventListener(FlexEvent.ENTER, onEnterNewBt);
			btnsView.removeChild(newBtInput);
			newConfirmBtn.removeEventListener(MouseEvent.CLICK, onNewConfirmClick);
			btnsView.removeChild(newConfirmBtn);
			newBtInput = null;
			newConfirmBtn = null;
		}
		
		private function onSave(e:MouseEvent):void
		{
			if(Data.getInstance().updateBehavior(btBar.selectedItem, editView.export()))
				Alert.show("保存成功");
		}
		
		private function onBehaviorClick(e:MouseEvent):void
		{
			var selectedNode:XML = (e.currentTarget as Tree).selectedItem as XML;
			var label:String=selectedNode.@label;
			this.setCurrBehavior(label);
			btBar.selectedIndex = -1;
			if(newBtInput)
				newBtInput.text = label;
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
		
		private function onNodeMouseDown(e:MouseEvent):void
		{
			var node:BNode = e.currentTarget as BNode;
			currNode = BNodeFactory.createBNode(node.type);
			currNode.x = this.mouseX-10;
			currNode.y = this.mouseY-15;
			currNode.alpha = 0.5;
			grabLayer.addChild(currNode);
		}
		
		private function onClose(e:CloseEvent):void
		{
			editView.remove();
			PopUpManager.removePopUp(this);
		}
	}
}