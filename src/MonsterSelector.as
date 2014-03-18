package
{
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	import spark.components.TextInput;
	import spark.components.VGroup;
	
	import Trigger.EditTriggers;
	
	import behaviorEdit.BTEditPanel;
	
	import mapEdit.AreaTriggerComponent;
	import mapEdit.Component;
	import mapEdit.EntityComponent;
	
	public class MonsterSelector extends VGroup
	{
		private var mSelected:Component = null;
		
		private static const kGRID_WIDTH:int 	= 100;
		private static const kGRID_HEIGHT:int 	= 100;
		
		private var mMonsters:Array = [];
		private var mScrollingLayer:UIComponent = null;
		
		private var mSearchBox:TextInput = new TextInput;
		
		public function MonsterSelector()
		{	
			with( this ) { // style configs
				paddingLeft = 5; paddingTop = 5; gap = 0; autoLayout = true;
			}
			
			// 
			this.mSearchBox = new TextInput;
			with( this.mSearchBox ) {
				prompt = "搜索"; percentWidth = 100; height = 30;
			}
			this.addEventListener( Event.CHANGE, onSearching );
			this.addElement( this.mSearchBox );
			
			mScrollingLayer = new UIComponent;
			this.addElement(mScrollingLayer);
		}
		
		public function reset( lid:String ):void 
		{
			// explicitly remove mats array
			mMonsters = null;
			mMonsters = new Array;
			
			var triggerMat:Component = new AreaTriggerComponent();
			triggerMat.trim(70);
			mMonsters.push(triggerMat);
			
			var enemies:Object = Data.getInstance().getEnemiesByLevelId(lid);
			for( var item:String in enemies )
			{
				var entity:Component = new EntityComponent(null, item, 80, 90);
				this.registerEventHandler( entity );
				this.mMonsters.push( entity );
			}
			
			mMonsters.sort(function(a:*, b:*):int{
				return int(a.type) < int(b.type) ? -1 : 1;
			}); 
			
			this.relayout( mMonsters );
		}
		
		private function onSearching(e:Event):void
		{
			var text:String = TextInput(e.target).text;
			var itemsToShow:Array = mMonsters.filter(
				function(a:*, index:int, arr:Array):Boolean
				{
					return ((a.type as String).search(text) == 0);
				}	
			);
			
			this.relayout(itemsToShow);
		}
		
		private function relayout(itemList:Array, cols:int = 2):void
		{
			// clean up
			mScrollingLayer.removeChildren();
	
			var iterX:int = 0;
			var px:int = 0, py:int = 0;
			for each( var item:Component in itemList )
			{
				px = 60 + iterX * MonsterSelector.kGRID_WIDTH;
				if( iterX % cols == 0 ) py += MonsterSelector.kGRID_HEIGHT;
				
				with( item ) { x = px; y = py; }
				this.mScrollingLayer.addChild( item );
				iterX = (++iterX)%cols 
			}

			with( this ) { height = item.y + 130; }
		}
		
		
		private function selectItem(target:Component):void
		{
			if(target != this.mSelected)
			{
				this.clearSelection();
				this.mSelected = target;
				this.mSelected.select(true);
				Runtime.getInstance().selectedComponentType = target.type;
			}
			else if(this.mSelected) this.clearSelection();
		}
		
		private function clearSelection():void
		{
			if(this.mSelected)
			{
				Runtime.getInstance().selectedComponentType = null;
				this.mSelected.select(false);
				this.mSelected = null;
			}
		}
		
		private function registerEventHandler(item:Component):void
		{
			item.doubleClickEnabled = true;
			item.mouseChildren = false;
			
			var self:MonsterSelector = this;
			item.addEventListener(MouseEvent.DOUBLE_CLICK, function(e:MouseEvent):void
			{
				var target:EntityComponent = e.currentTarget as EntityComponent;
				if(target) MonsterSelector.OpenBehaviorEditor( target );
			});
			item.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				var target:Component = e.currentTarget as Component;
				if(target) self.selectItem( target );
			});
						
			var menu:ContextMenu = new ContextMenu;
			var bhButton:ContextMenuItem = new ContextMenuItem("行为");
			bhButton.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
				function(e:ContextMenuEvent):void
				{
					var target:EntityComponent = e.contextMenuOwner as EntityComponent;
					if(target) MonsterSelector.OpenBehaviorEditor( target );
				}
			);
			menu.addItem(bhButton);
			
			var trigger:ContextMenuItem = new ContextMenuItem("触发器");
			trigger.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
				function(e:ContextMenuEvent):void
				{
					var target:EntityComponent = e.contextMenuOwner as EntityComponent;
					if(target) MonsterSelector.OpenTriggerEditor( target );
				});
			menu.addItem(trigger);
			
			item.contextMenu = menu;
		}
		
		//---------------------
		// actions
		//---------------------
		static private function OpenTriggerEditor(target:EntityComponent):void
		{
			var win:EditTriggers = new EditTriggers(target);
			PopUpManager.addPopUp(win, MapEditor.getInstance());
			PopUpManager.centerPopUp(win);
			win.x = FlexGlobals.topLevelApplication.stage.stageWidth/2-win.width/2;
			win.y = FlexGlobals.topLevelApplication.stage.stageHeight/2-win.height/2;
		}
		
		static private function OpenBehaviorEditor(target:EntityComponent):void
		{
			var btPanel:BTEditPanel = new BTEditPanel(target);
			PopUpManager.addPopUp(btPanel, MapEditor.getInstance());
			PopUpManager.centerPopUp(btPanel);
			btPanel.x = FlexGlobals.topLevelApplication.stage.stageWidth/2-btPanel.width/2;
			btPanel.y = FlexGlobals.topLevelApplication.stage.stageHeight/2-btPanel.height/2;
		}
	}
}