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
	
	public class BulletSelector extends VGroup
	{
		private var mSelected:Component = null;
		
		private static const kGRID_WIDTH:int 	= 100;
		private static const kGRID_HEIGHT:int 	= 100;
		
		private var mMonsters:Array = [];
		private var mScrollingLayer:UIComponent = null;
		
		private var mSearchBox:TextInput = new TextInput;
		
		public function BulletSelector()
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
			
			var self:BulletSelector = this;
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
			var enemies:Object = Data.getInstance().getBulletsByLevelId(lid);
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
			with( this ) { height = 130; }
			for each( var item:Component in itemList )
			{
				px = 60 + iterX * BulletSelector.kGRID_WIDTH;
				if( iterX % cols == 0 ) py += BulletSelector.kGRID_HEIGHT;
				iterX = (++iterX)%cols;
				
				with( item ) { x = px; y = py; }
				with( this ) { height = item.y + 130; }
				if( item as AreaTrigger )
					item.y -= BulletSelector.kGRID_HEIGHT/4;
				
				this.mScrollingLayer.addChild( item );
			}
		}
		
		
		private function registerEventHandler(item:Component):void
		{
			item.doubleClickEnabled = true;
			item.mouseChildren = false;
			
			var self:BulletSelector = this;
			item.addEventListener(MouseEvent.DOUBLE_CLICK, function(e:MouseEvent):void
			{
				MapEditor.getInstance().mEditMonster.onEditBullet( 
					Runtime.getInstance().currentLevelID, item.classId
				);
			});
		}
	}
}