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
	
	public class UserPanel extends Panel
	{
		private var parPanel:BTEditPanel = null;
		private var btnsView:UIComponent = null;
		private var newBtInput:TextInput = null;
		private var newConfirmBtn:Button = null;
		private var cancelBtn:Button = null;
		
		public function UserPanel(par:BTEditPanel)
		{
			parPanel = par;
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
			newBtn.addEventListener(MouseEvent.CLICK, onNewBT);
			btnsView.addChild(newBtn);
			
			
			var icon:EditBase = new MatSprite(null, parPanel.editTargetType, 100, 70);
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
		}
		
		private function onNewBT(e:MouseEvent):void
		{
			if(parPanel.state != BTEditState.NEW_BT)
			{
				parPanel.state = BTEditState.NEW_BT;
				parPanel.editView.clear();
				
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
		}
		
		public function setNewBt(bName:String):void
		{
			onNewBT(null);
			newBtInput.text = bName;
			parPanel.setCurrBehavior(bName);
		}
		
		private function onEnterNewBt(e:FlexEvent):void
		{
			onNewConfirmClick(null);
		}
		
		private function onSave(e:MouseEvent):void
		{
			if(parPanel.save())
				Alert.show("保存成功");
			else if(parPanel.state == BTEditState.NEW_BT)
				onNewConfirmClick(null);
		}
		
		public function onNewConfirmClick(e:MouseEvent):void
		{
			var bName:String = newBtInput.text;
			if(newBtInput.text.length == 0)
			{
				Alert.show("行为名不能为空！");
			}
			else if(Data.getInstance().enemyContainsBehavior(parPanel.editTargetType, newBtInput.text))
			{
				Alert.show("该行为已经存在！");
				return;
			}
			else
			{
				parPanel.addNewBT(bName);
			}
			
			onCancel();
		}
		
		private function onCancel(e:MouseEvent = null):void
		{
			parPanel.state = BTEditState.EXEC_BT;
			newBtInput.removeEventListener(FlexEvent.ENTER, onEnterNewBt);
			btnsView.removeChild(newBtInput);
			newConfirmBtn.removeEventListener(MouseEvent.CLICK, onNewConfirmClick);
			btnsView.removeChild(newConfirmBtn);
			btnsView.removeChild(cancelBtn);
			newBtInput = null;
			newConfirmBtn = null;
			cancelBtn = null;
		}
		
		private function onNodeMouseDown(e:MouseEvent):void
		{
			var node:BNode = e.currentTarget as BNode;
			parPanel.setCurrSelectNode(node.type);
		}
	}
}