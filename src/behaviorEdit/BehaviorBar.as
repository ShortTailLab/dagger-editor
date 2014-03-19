package behaviorEdit
{
	import com.hurlant.crypto.symmetric.NullPad;
	
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
	import spark.components.TabBar;
	
	import manager.EventManager;
	
	import tools.RenamePanel;
	
	public class BehaviorBar extends TabBar
	{
		private var btBar:TabBar = null;
		private var controller:BTEditController = null;
		private var newBtn:Button;
		private var menu:ContextMenu;
		
		public function BehaviorBar(_controller:BTEditController)
		{
			controller = _controller;
			
			//btBar.setStyle("chromeColor", "#EEE8AA"); 
			this.height = 40;
			this.x = 120;
			this.dataProvider = controller.getBTs();
			this.selectedIndex = 0;
			//btBar.addEventListener(IndexChangeEvent.CHANGE, onChangeBt);
			this.addEventListener(MouseEvent.CLICK, onClickBt);
			
			menu = new ContextMenu;
			var item2:ContextMenuItem = new ContextMenuItem("重命名");
			item2.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onRenameBT);
			var item3:ContextMenuItem = new ContextMenuItem("删除");
			item3.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onDeleteEnemyBT);
			menu.addItem(item2);
			menu.addItem(item3);
			this.contextMenu = menu;
			
			updateBar();
			EventManager.getInstance().addEventListener(BehaviorEvent.BT_ADDED, function(e):void{updateBar();});
			EventManager.getInstance().addEventListener(BehaviorEvent.BT_REMOVED, function(e):void{updateBar();});
			EventManager.getInstance().addEventListener(BehaviorEvent.CREATE_NEW_BT, onCreateNewBT);
			EventManager.getInstance().addEventListener(BehaviorEvent.CREATE_BT_DONE, onCreateDone);
			EventManager.getInstance().addEventListener(BehaviorEvent.CREATE_BT_CANCEL, onCreateDone);
		}
		
		
		private function onCreateNewBT(e:BehaviorEvent):void
		{
			this.selectedIndex = 0;
			this.contextMenu = null;
			this.removeEventListener(MouseEvent.CLICK, onClickBt);
			this.alpha = 0.5;
		}
		
		private function onCreateDone(e:BehaviorEvent):void
		{
			this.contextMenu = menu;
			this.addEventListener(MouseEvent.CLICK, onClickBt);
			this.alpha = 1;
		}
		
		public function updateBar():void
		{
			if(controller.getBTs().length == 0)
			{
				this.dataProvider = new ArrayCollection(["新建"]);
			}
			else if(controller.getBTs().length > 0 && this.dataProvider != controller.getBTs())
			{
				this.dataProvider = controller.getBTs();
			}
		}
		
		
		private function onClickBt(e:MouseEvent):void
		{
			if(controller.getBTs().length > 0)
				controller.setCurrEditBehavior(this.selectedItem);
			else
				EventManager.getInstance().dispatchEvent(new BehaviorEvent(BehaviorEvent.CREATE_NEW_BT));
		}
		
		private function onDeleteEnemyBT(e:ContextMenuEvent):void
		{
			controller.removeBTByIndex(this.selectedIndex);
		}
		
		private function onRenameBT(e:ContextMenuEvent):void
		{
			new RenamePanel( function( bid:String=null ):void {
				if( !bid ) return;
				if( bid.length > 0 )
				{
					controller.renameBTbyIndex(this.selectedIndex, bid);
					Alert.okLabel = "确定";
				}else 
					Alert.show("【错误】命名不能为空");
			}, this);
		}
	}
}