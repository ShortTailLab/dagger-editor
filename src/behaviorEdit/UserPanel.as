package behaviorEdit
{
	import flash.events.MouseEvent;
	
	import mx.controls.Button;
	import mx.core.UIComponent;
	
	import spark.components.Label;
	import spark.components.Panel;
	import spark.components.TextInput;
	
	import mapEdit.Component;
	import mapEdit.Entity;
	
	public class UserPanel extends Panel
	{
		private var parPanel:BTEditPanel = null;
		private var btnsView:UIComponent = null;
		private var newBtInput:TextInput = null;
		private var newConfirmBtn:Button = null;
		private var cancelBtn:Button = null;
		private var controller:BTEditController = null;
		private var mBehaviorLabel = null;
		
		public function UserPanel(par:BTEditPanel, _controller:BTEditController)
		{
			parPanel = par;
			controller = _controller;
			this.title = "类型";
			this.width = 120;
			this.percentHeight = 100;
			
			btnsView = new UIComponent;
			this.addElement(btnsView);
			
			mBehaviorLabel = new Label();
			mBehaviorLabel.text = controller.getUnitBehaviorName();
			mBehaviorLabel.width = 80;
			mBehaviorLabel.height = 30;
			mBehaviorLabel.x = 20;
			mBehaviorLabel.y = 140;
			btnsView.addChild(mBehaviorLabel);
			
			var setBehaviorButton = new Button();
			setBehaviorButton.label = "使用当前行为";
			setBehaviorButton.width = 100;
			setBehaviorButton.height = 30;
			setBehaviorButton.x = 10;
			setBehaviorButton.y = 180;
			setBehaviorButton.addEventListener(MouseEvent.CLICK, onSetClick);
			btnsView.addChild(setBehaviorButton);
			
			
			var icon:Entity = new Entity( controller.editTargetType);
			icon.setSize( 100 );
			icon.x = 60;
			icon.y = 110;
			btnsView.addChild(icon);
			
			var btypes:Array = [BType.BTYPE_EXEC, BType.BTYPE_SEQ, BType.BTYPE_SEL,
				BType.BTYPE_PAR, BType.BTYPE_COND, BType.BTYPE_LOOP];

			for(var i:int = 0; i < btypes.length; i++)
			{
				var node:BNode = BNodeFactory.createBNode(btypes[i]);
				node.x = 20;
				node.y = 300+50*i;
				node.addEventListener(MouseEvent.MOUSE_DOWN, onNodeMouseDown);
				btnsView.addChild(node);
			}
		}
		
		private function onSetClick(e:MouseEvent):void
		{
			controller.setUnitBehavior( controller.selectedBehavior );
		}
		
		private function onNodeMouseDown(e:MouseEvent):void
		{
			var node:BNode = e.currentTarget as BNode;
			parPanel.setCurrSelectNode(node.type);
		}
		
		public function get behaviorLabel():Label
		{
			return mBehaviorLabel;
		}
		
		/*
		private function onEnterNewBt(e:FlexEvent):void
		{
			onNewConfirmClick(null);
		}
		
		private function onSave(e:MouseEvent):void
		{
			controller.saveSelectItem();
		}*/
		
		/*
		public function onNewConfirmClick(e:MouseEvent):void
		{
			var bName:String = newBtInput.text;
			if(newBtInput.text.length == 0)
			{
				Alert.show("行为名不能为空！");
				return;
			}
			
			var behaviors:Array = Data.getInstance().getEnemyBehaviorsById( 
				Runtime.getInstance().currentLevelID, controller.editTargetType 
			) as Array || [];
			
			if( behaviors && behaviors.indexOf( newBtInput.text ) >= 0 )
			{
				Alert.show("该行为已经存在！");
				return;
			}
			
			controller.addBT(bName);
			EventManager.getInstance().dispatchEvent(new BehaviorEvent(BehaviorEvent.CREATE_BT_DONE, bName));
			onCreateCancel();
		}*/
		
		/*
		public function onCancel(e:MouseEvent = null):void
		{
			EventManager.getInstance().dispatchEvent(new BehaviorEvent(BehaviorEvent.CREATE_BT_CANCEL));
		}
		*/
	}
}