package behaviorEdit
{
	import flash.events.MouseEvent;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import spark.components.Panel;
	import spark.components.TextInput;
	
	import editEntity.EditBase;
	import editEntity.MatSprite;
	
	import manager.EventManager;
	
	public class UserPanel extends Panel
	{
		
		private var parPanel:BTEditPanel = null;
		private var btnsView:UIComponent = null;
		private var newBtInput:TextInput = null;
		private var newConfirmBtn:Button = null;
		private var cancelBtn:Button = null;
		private var controller:BTEditController = null;
		
		public function UserPanel(par:BTEditPanel, _controller:BTEditController)
		{
			parPanel = par;
			controller = _controller;
			this.title = "类型";
			this.width = 120;
			this.percentHeight = 100;
			btnsView = new UIComponent;
			this.addElement(btnsView);
			this.addElement(this);
			
			var saveBtn:Button = new Button;
			saveBtn.label = "保存";
			saveBtn.width = 80;
			saveBtn.height = 30;
			saveBtn.x = 20;
			saveBtn.y = 140;
			saveBtn.addEventListener(MouseEvent.CLICK, onSave);
			btnsView.addChild(saveBtn);
			
			var newBtn:Button = new Button;
			newBtn.label = "添加行为";
			newBtn.width = 80;
			newBtn.height = 30;
			newBtn.x = 20;
			newBtn.y = 180;
			newBtn.addEventListener(MouseEvent.CLICK, onAddClick);
			btnsView.addChild(newBtn);
			
			
			var icon:EditBase = new MatSprite(null, controller.editTargetType, 100, 70);
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
				node.y = 300+50*i;
				node.addEventListener(MouseEvent.MOUSE_DOWN, onNodeMouseDown);
				btnsView.addChild(node);
			}
			
			EventManager.getInstance().addEventListener(BehaviorEvent.CREATE_NEW_BT, onNewBT);
			EventManager.getInstance().addEventListener(BehaviorEvent.CREATE_BT_CANCEL, onCreateCancel);
		}
		
		private function onAddClick(e:MouseEvent):void
		{
			if(!controller.isCreatingNew)
				EventManager.getInstance().dispatchEvent(new BehaviorEvent(BehaviorEvent.CREATE_NEW_BT));
		}
		
		private function onNewBT(e:BehaviorEvent):void
		{
			if(!newBtInput)
			{
				newBtInput = new TextInput;
				newBtInput.width = 100;
				newBtInput.height = 30;
				newBtInput.x = 10;
				newBtInput.y = 220;
				newBtInput.prompt = "输入行为名";
				newBtInput.addEventListener(FlexEvent.ENTER, onEnterNewBt);
				btnsView.addChild(newBtInput);
				
				newConfirmBtn = new Button;
				newConfirmBtn.label = "确定";
				newConfirmBtn.width = 45;
				newConfirmBtn.height = 25;
				newConfirmBtn.x = 10;
				newConfirmBtn.y = 255;
				newConfirmBtn.addEventListener(MouseEvent.CLICK, onNewConfirmClick);
				btnsView.addChild(newConfirmBtn);
				
				cancelBtn = new Button;
				cancelBtn.label = "取消";
				cancelBtn.width = 45;
				cancelBtn.height = 25;
				cancelBtn.x = 65;
				cancelBtn.y = 255;
				cancelBtn.addEventListener(MouseEvent.CLICK, onCancel);
				btnsView.addChild(cancelBtn);
			}
			newBtInput.text = e.msg;
		}
		
		private function onCreateCancel(e:BehaviorEvent = null):void
		{
			if(newBtInput)
			{
				newBtInput.removeEventListener(FlexEvent.ENTER, onEnterNewBt);
				btnsView.removeChild(newBtInput);
				newConfirmBtn.removeEventListener(MouseEvent.CLICK, onNewConfirmClick);
				btnsView.removeChild(newConfirmBtn);
				btnsView.removeChild(cancelBtn);
				newBtInput = null;
				newConfirmBtn = null;
				cancelBtn = null;
			}
		}
		
		private function onEnterNewBt(e:FlexEvent):void
		{
			onNewConfirmClick(null);
		}
		
		private function onSave(e:MouseEvent):void
		{
			controller.saveSelectItem();
		}
		
		public function onNewConfirmClick(e:MouseEvent):void
		{
			var bName:String = newBtInput.text;
			if(newBtInput.text.length == 0)
			{
				Alert.show("行为名不能为空！");
				return;
			}
			else if(Data.getInstance().enemyContainsBehavior(controller.editTargetType, newBtInput.text))
			{
				Alert.show("该行为已经存在！");
				return;
			}
			else
			{
				controller.addBT(bName);
				EventManager.getInstance().dispatchEvent(new BehaviorEvent(BehaviorEvent.CREATE_BT_DONE, bName));
				onCreateCancel();
			}
		}
		
		public function onCancel(e:MouseEvent = null):void
		{
			EventManager.getInstance().dispatchEvent(new BehaviorEvent(BehaviorEvent.CREATE_BT_CANCEL));
		}
		
		
		private function onNodeMouseDown(e:MouseEvent):void
		{
			var node:BNode = e.currentTarget as BNode;
			parPanel.setCurrSelectNode(node.type);
		}
	}
}