package
{
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	import manager.EventManager;
	import manager.EventType;
	import manager.GameEvent;
	import editEntity.MatFactory;
	import editEntity.MatSprite;
	import editEntity.TriggerSprite;
	import editEntity.EditBase;
	
	public class MatsView extends UIComponent
	{
		
		public var selected:EditBase = null;
		
		private var mats:Array = null;
		
		private var grid_width:int = 110;
		private var grid_height:int = 150;
		
		public function MatsView()
		{
			mats = new Array;
			init();
			
			EventManager.getInstance().addEventListener(EventType.ENEMY_DATA_UPDATE, init); 
		}
		
		public function init(e:GameEvent = null):void
		{
			while(mats.length > 0)
			{
				var m:EditBase = mats.pop();
				m.removeEventListener(MouseEvent.DOUBLE_CLICK, onMatDoubleClick);
				m.removeEventListener(MouseEvent.CLICK, onMatClick);
			}
			this.removeChildren();
			
			var triggerMat:EditBase = MatFactory.createMat(TriggerSprite.TRIGGER_TYPE);
			triggerMat.trim(70);
			add(triggerMat);
			
			var data:Object = Data.getInstance().enemyData;
			for(var item in data)
			{
				var view:EditBase = MatFactory.createMat(item, 70);
				view.trim(100);
				add(view);
			}
			resize(2);
		}
		
		private function add(view:EditBase):void
		{
			view.doubleClickEnabled = true;
			view.addEventListener(MouseEvent.DOUBLE_CLICK, onMatDoubleClick);
			view.addEventListener(MouseEvent.CLICK, onMatClick);
			this.addChild(view);
			mats.push(view);
			
			var menu:ContextMenu = new ContextMenu;
			var btn:ContextMenuItem = new ContextMenuItem("编辑");
			btn.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				edit(e.contextMenuOwner as MatSprite);
			});
			menu.addItem(btn);
			
			view.contextMenu = menu;
		}
		
		private function edit(target:MatSprite):void
		{
			if(target)
			{ 
				var win:EditPanel = new EditPanel(target);
				PopUpManager.addPopUp(win, this);
				PopUpManager.centerPopUp(win);
				win.x = FlexGlobals.topLevelApplication.stage.stageWidth/2-win.width/2;
				win.y = FlexGlobals.topLevelApplication.stage.stageHeight/2-win.height/2;
			}
		}
		
		
		public function onMatClick(e:MouseEvent):void
		{
			var target:EditBase = e.currentTarget as EditBase;
			var prev:EditBase = selected;
			if(selected)
			{
				selected.select(false);
				selected = null;
			}
			if(target != prev)
			{
				selected = target;
				selected.select(true);
			}
		}
		
		public function onMatDoubleClick(e:MouseEvent):void
		{
			edit(e.currentTarget as MatSprite);
		}
		
		public function resize(cols:int):void
		{
			for(var i:int = 0; i < mats.length; i++)
			{
				mats[i].x = 60+i%cols*grid_width;
				mats[i].y = 130+int(i/cols)*grid_height;
			}
			this.height = mats[mats.length-1].y+130;
		}
	}
}