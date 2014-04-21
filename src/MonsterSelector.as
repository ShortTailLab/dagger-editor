package
{
	import BTEdit.BTPanel;
	
	import Trigger.EditTriggers;
	
	import behaviorEdit.BTEditPanel;
	
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import manager.EventManager;
	import manager.EventType;
	import manager.GameEvent;
	
	import mapEdit.AreaTrigger;
	import mapEdit.Component;
	import mapEdit.Entity;
	
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	import spark.components.TextInput;
	import spark.components.VGroup;
	
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
			this.mSearchBox.addEventListener( Event.CHANGE, onSearching );
			this.addElement( this.mSearchBox );
			
			mScrollingLayer = new UIComponent;
			this.addElement(mScrollingLayer);
			
			var self:MonsterSelector = this;
			Runtime.getInstance().addEventListener( Runtime.SELECT_DATA_CHANGE,
				function(e:Event):void {
					if( !Runtime.getInstance().selectedComponentType && self.mSelected )
					{
						self.clearSelection();
					}
				}
			);
			
			Runtime.getInstance().addEventListener( Runtime.CURRENT_LEVEL_CHANGE,
				function(evt:Event):void {
					self.reset( Runtime.getInstance().currentLevelID );	
				}
			);
			
			Runtime.getInstance().addEventListener( Runtime.PROFLE_DATA_CHANGE,
				function(evt:Event):void {
					self.reset( Runtime.getInstance().currentLevelID );
				}
			);
		}
		
		public function reset( lid:String ):void 
		{
			// explicitly remove mats array
			mMonsters = [];
			
			var self:MonsterSelector = this;
			var triggerMat:Component = new AreaTrigger;
			triggerMat.setBaseSize( 70 );
			this.registerEventHandler( triggerMat );
			mMonsters.push(triggerMat);
			
			var enemies:Object = Data.getInstance().getMonstersByLevelId(lid);
			for( var item:String in enemies )
			{
				var entity:Entity = new Entity( item, true );
				entity.setSize(70);
				this.registerEventHandler( entity );
				this.mMonsters.push( entity );
			}
			
			mMonsters.sort(function(a:*, b:*):int{
				return int(a.classId) < int(b.classId) ? -1 : 1;
			}); 
			
			this.relayout( mMonsters );
		}
		
		private function onSearching(e:Event):void
		{
			var text:String = TextInput(e.target).text;
			var itemsToShow:Array = mMonsters.filter(
				function(a:*, index:int, arr:Array):Boolean
				{
					return ((a.classId as String).search(text) == 0);
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
			with( this ) { height = 130; }
			for each( var item:Component in itemList )
			{
				px = 60 + iterX * MonsterSelector.kGRID_WIDTH;
				if( iterX % cols == 0 ) py += MonsterSelector.kGRID_HEIGHT;
				iterX = (++iterX)%cols;
				
				with( item ) { x = px; y = py; }
				with( this ) { height = item.y + 130; }
				if( item as AreaTrigger )
					item.y -= MonsterSelector.kGRID_HEIGHT/4;
				
				this.mScrollingLayer.addChild( item );
			}
		}
		
		
		private function selectItem(target:Component):void
		{
			if(target != this.mSelected)
			{
				this.clearSelection();
				this.mSelected = target;
				this.mSelected.select(true);
				Runtime.getInstance().selectedComponentType = target.classId;
			}
		}
		
		private function clearSelection():void
		{
			if(this.mSelected)
			{
				this.mSelected.select(false);
				this.mSelected = null;
				Runtime.getInstance().selectedComponentType = null;
			}
		}
		
		private function registerEventHandler(item:Component):void
		{
			item.doubleClickEnabled = true;
			item.mouseChildren = false;
			
			var self:MonsterSelector = this;
			item.addEventListener(MouseEvent.DOUBLE_CLICK, function(e:MouseEvent):void
			{
				MapEditor.getInstance().mEditMonster.onEditEnemy( 
					Runtime.getInstance().currentLevelID, item.classId
				);
				self.clearSelection();
			});
			item.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
			{
				var target:Component = e.currentTarget as Component;
				if(target) self.selectItem( target );
			});
						
			var menu:ContextMenu = new ContextMenu;
			
			var editButton:ContextMenuItem = new ContextMenuItem("数据");
			editButton.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
				function(e:ContextMenuEvent):void
				{
					MapEditor.getInstance().mEditMonster.onEditEnemy( 
						Runtime.getInstance().currentLevelID, item.classId
					);
				}
			);
			menu.addItem( editButton );
			
			var bhButton:ContextMenuItem = new ContextMenuItem("行为");
			bhButton.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
				function(e:ContextMenuEvent):void
				{
					var enemy:Object = Data.getInstance().getEnemyProfileById( 
						Runtime.getInstance().currentLevelID, item.classId
					);
					
					if( !enemy || enemy.type != EditMonster.kCONFIGURABLE )
						return;
					
					var target:Entity = e.contextMenuOwner as Entity;
					if(target) MonsterSelector.OpenBehaviorEditor( target );
				}
			);
			menu.addItem(bhButton);
			
			var trigger:ContextMenuItem = new ContextMenuItem("触发器");
			trigger.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
				function(e:ContextMenuEvent):void
				{
					var target:Entity = e.contextMenuOwner as Entity;
					if(target) MonsterSelector.OpenTriggerEditor( target );
				});
			menu.addItem(trigger);
			
			item.contextMenu = menu;
		}
		
		//---------------------
		// actions
		//---------------------
		static private function OpenTriggerEditor(target:Entity):void
		{
			var win:EditTriggers = new EditTriggers(target);
			PopUpManager.addPopUp(win, MapEditor.getInstance());
			PopUpManager.centerPopUp(win);
			win.x = FlexGlobals.topLevelApplication.stage.stageWidth/2-win.width/2;
			win.y = FlexGlobals.topLevelApplication.stage.stageHeight/2-win.height/2;
		}
		
		static private var selectedTarget:Entity;
		static private var btEdit:BTPanel;
		static private function OpenBehaviorEditor(target:Entity):void
		{
			selectedTarget = target;
			EventManager.getInstance().addEventListener(EventType.BT_EDIT_PANEL_CREATE, onBehaviorEditCreate);
			btEdit = new BTPanel();
			PopUpManager.addPopUp(btEdit, MapEditor.getInstance());
		}
		
		static private function onBehaviorEditCreate(event:GameEvent):void {
			EventManager.getInstance().removeEventListener(EventType.BT_EDIT_PANEL_CREATE, onBehaviorEditCreate);
			btEdit.init(selectedTarget, FlexGlobals.topLevelApplication.stage.stageWidth, FlexGlobals.topLevelApplication.stage.stageHeight);
		}
	}
}