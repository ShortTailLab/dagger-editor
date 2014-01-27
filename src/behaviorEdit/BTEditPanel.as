package behaviorEdit
{
	import flash.events.ContextMenuEvent;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Tree;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.HScrollBar;
	import spark.components.Panel;
	import spark.components.TitleWindow;
	import spark.components.VGroup;
	import spark.components.VScrollBar;
	
	import editEntity.EditBase;
	import editEntity.MatFactory;
	import editEntity.MatSprite;
	
	import manager.EventManager;
	
	public class BTEditPanel extends TitleWindow
	{
		public var currNode:BNode = null;
		private var grabLayer:UIComponent = null;
		private var editType:String;
		private var editView:BTEditView;
		private var currBName:String = "";
		private var currBData:Object = null;
		
		private var bnameLabel:TextField = null;
		
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
			var _tree:Tree = new Tree;
			_tree.dataProvider = Data.getInstance().behaviorsXML;
			_tree.enabled = true;
			_tree.labelField = "@label";
			_tree.percentWidth = 100;
			_tree.percentHeight = 100;
			_tree.showRoot = false;
			_tree.addEventListener(MouseEvent.CLICK, onBehaviorClick);
			behaviorsPanel.addElement(_tree);
			
			var btnsPanel:Panel = new Panel;
			btnsPanel.title = "类型";
			btnsPanel.width = 120;
			btnsPanel.percentHeight = 100;
			var btnsView:UIComponent = new UIComponent;
			btnsPanel.addElement(btnsView);
			this.addElement(btnsPanel);
			
			
			btnsView.addChild((Utils.getLabel("行为ID：", 10, 150, 14)));
			bnameLabel = Utils.getLabel("", 10, 170, 14);
			bnameLabel.width = 100;
			bnameLabel.height = 20;
			bnameLabel.border = true;
			btnsView.addChild(bnameLabel);
			
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
				node.y = 200+50*i;
				node.addEventListener(MouseEvent.MOUSE_DOWN, onNodeMouseDown);
				btnsView.addChild(node);
			}
			
			var btn:Button = new Button;
			btn.label = "保存";
			btn.width = 80;
			btn.height = 30;
			btn.x = 20;
			btn.y = node.y + 80;
			btn.addEventListener(MouseEvent.CLICK, onSave);
			btnsView.addChild(btn);
			
			var editGroup:HGroup = new HGroup();
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
			
			initEditView();
			
			this.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.addEventListener(CloseEvent.CLOSE, onClose);
		}
		
		private function initEditView():void
		{
			var bs:Array = Data.getInstance().enemyBTData[editType] as Array;
			if(bs.length > 0)
			{
				setCurrBehavior(bs[0]);
			}
			else
				trace("enemy behaviors is null");
			 
		}
		
		private function setCurrBehavior(name:String):void
		{
			this.currBName = name;
			bnameLabel.text = this.currBName;
			editView.init(Data.getInstance().behaviorsData[name]);
		}
		
		private function onSave(e:MouseEvent):void
		{
			currBData = editView.export();
			if(!currBData)
				Data.getInstance().setEnemyBehavior(editType, "");
			else if(currBName != "" && Data.getInstance().behaviorsData.hasOwnProperty(currBName))
			{
				Alert.okLabel = "更新";
				Alert.noLabel = "新建";
				Alert.show("该来自行为库的行为还是新建一个？", "tips", Alert.OK|Alert.NO, this, alertClose);
			}
			else if(currBName.length == 0)
				newBehavior();
		}
		
		
		private function alertClose(e:CloseEvent):void
		{
			if(e.detail == Alert.OK)
			{
				Data.getInstance().updateBehavior(currBName, currBData);
				Data.getInstance().setEnemyBehavior(editType, currBName);
				Alert.okLabel = "确定";
			}
			else if(e.detail == Alert.NO)
			{
				newBehavior();
			}
		}
		
		private function newBehavior():void
		{
			var window:RenamePanel = new RenamePanel;
			window.addEventListener(MsgEvent.RENAME_LEVEL, onSaveConfirm);
			
			PopUpManager.addPopUp(window, this, true);
			PopUpManager.centerPopUp(window);
		}
		
		private function onSaveConfirm(e:MsgEvent):void
		{
			if(e.hintMsg.length > 0)
			{
				currBName = e.hintMsg;
				bnameLabel.text = this.currBName;
				Data.getInstance().addBehaviors(currBName, currBData);
				Data.getInstance().setEnemyBehavior(editType, currBName);
				Alert.okLabel = "确定";
			}
			else
				Alert.show("命名不能未空");
		}
		
		private function onBehaviorClick(e:MouseEvent):void
		{
			var selectedNode:XML = (e.currentTarget as Tree).selectedItem as XML;
			var label:String=selectedNode.@label;
			this.setCurrBehavior(label);
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