/*
this view contains the map,the time scroller, the inputform.
*/
package 
{
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import manager.MsgInform;
	
	import mapEdit.AreaTrigger;
	import mapEdit.Component;
	import mapEdit.Coordinator;
	import mapEdit.Entity;
	import mapEdit.MainSceneXML;
	
	import mx.controls.Alert;
	import mx.core.IVisualElement;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.events.SliderEvent;
	
	import spark.components.Group;
	import spark.core.SpriteVisualElement;
	
	public class MainScene extends MainSceneXML
	{
		[Embed(source="map_snow1.png")]
		static public var BgImage:Class;
		
		public static const kSCENE_WIDTH:Number = 720;
		public static const kSCENE_HEIGHT:Number = 1280;
		
		private var mLevelId:String 				= null;

		private var mComponents:Vector.<Component> 	= null;
		private var mMonsterMask:SpriteVisualElement = null;
		
		private var mProgressInPixel:Number = 0;
		private var mFinishingLine:Number = 0;
		
		private var mSelectedTipsLayer:Group = null;
		private var mCoordinator:Coordinator = null;
		
		// configs
		private var mGridHeight:int 	= 16;
		private var mGridWidth:int 		= 32;
		private var mMapSpeed:Number 	= 32;
		
		// selections
		private var mReadyToPaste:Boolean 				= false;
		private var mSelectFrame:SpriteVisualElement 	= null;
		private var mSelectedComponents:Array 			= [];
		private var mFocusComponent:Component 			= null;
		
		// facilities
		private var mAutoSaver:Timer 		= null;
		private var mTipsFontSize:Number 	= 12;
		private var mPasteData:Array 		= [];
		private var mPasteTipsLayer:Group 	= null;
		
		public function MainScene()
		{
			with( this ) {
				percentWidth = 100; percentHeight = 100;
			}
		}
		
		// ------------------------------------------------------------
		// public operations 
		public function init():void 
		{
			var self:MainScene = this;
			
			Runtime.getInstance().addEventListener( Runtime.CURRENT_LEVEL_CHANGE, function(evt:Event):void
			{
				self.reset( Runtime.getInstance().currentLevelID );	
			});
			
			Runtime.getInstance().addEventListener( Runtime.PROFLE_DATA_CHANGE, function(evt:Event):void
			{
				self.reset( Runtime.getInstance().currentLevelID );
			});
			
			this.mTimeline.addEventListener( SliderEvent.CHANGE, 
				function( e:SliderEvent ): void {
					self.setProgress( e.value * self.mMapSpeed );
				}
			);
			
			// configs
			this.mMapSpeedInput.text 	= String(this.mMapSpeed);
			this.mMapSpeedInput.addEventListener( FlexEvent.ENTER,
				function (e:FlexEvent):void {
					self.mMapSpeed = int(self.mMapSpeedInput.text);
					Data.getInstance().setEditorConfig("mapSpeed", self.mMapSpeed);
				}
			);
			
			this.mShowGrid.selected = Data.getInstance().conf["main.scene.show.grid"] || false;
			this.mShowGrid.addEventListener( Event.CHANGE, 
				function (e:Event):void {
					Data.getInstance().setEditorConfig(
						"main.scene.show.grid", self.mShowGrid.selected
					);
					self.mCoordinator.showGrid( self.mShowGrid.selected );
					self.mCoordinator.setMeshDensity( 
						self.mGridWidth, self.mGridHeight, self.height-65, self.mProgressInPixel 
					);
				}
			);
			
			this.mRestrictGrid.selected = Data.getInstance().conf["main.scene.restrict.grid"] || false;
			this.mRestrictGrid.addEventListener( Event.CHANGE, 
				function (e:Event):void {
					Data.getInstance().setEditorConfig(
						"main.scene.restrict.grid", self.mRestrictGrid.selected
					);
				}
			);			
				
			this.mGridWidthInput.text 	= String(this.mGridWidth);
			this.mGridWidthInput.addEventListener( FlexEvent.ENTER,
				function (e:FlexEvent):void {
					self.mGridWidth = int(self.mGridWidthInput.text);
					Data.getInstance().setEditorConfig("gridWidth", self.mGridWidth);
					self.mCoordinator.setMeshDensity( 
						self.mGridWidth, self.mGridHeight, self.height-65, self.mProgressInPixel 
					);
				}
			);
			
			this.mGridHeightInput.text 	= String(this.mGridHeight);
			this.mGridHeightInput.addEventListener( FlexEvent.ENTER,
				function (e:FlexEvent):void {
					self.mGridHeight = int(self.mGridHeightInput.text);
					Data.getInstance().setEditorConfig("gridHeight", self.mGridHeight);
					self.mCoordinator.setMeshDensity( 
						self.mGridWidth, self.mGridHeight, self.height-65, self.mProgressInPixel 
					);
				}
			);
			
			// informations
			this.mInfoXInput.addEventListener( FlexEvent.ENTER,
				function (e:FlexEvent):void {
					if( self.mSelectedComponents.length == 1 )
					{
						self.mSelectedComponents[0].x = int(self.mInfoXInput.text)/2;
						self.onMonsterChange();
					}
				}
			);
			
			this.mInfoYInput.addEventListener( FlexEvent.ENTER,
				function (e:FlexEvent):void {
					if( self.mSelectedComponents.length == 1 )
					{
						self.mSelectedComponents[0].y = -int(self.mInfoYInput.text)/2;
						self.onMonsterChange();
					}
				}
			);	
			
			this.mInfoTimeInput.addEventListener( FlexEvent.ENTER,
				function (e:FlexEvent):void {
					for each( var item:Component in self.mSelectedComponents )
					{
						var t2:Entity = item as Entity;
						if( !t2 ) continue;
						
						t2.triggeredTime = Number(self.mInfoTimeInput.text);
						t2.showTimeTriggerTips();
					}
					self.onMonsterChange();
				}
			);	
			
			// others 
			this.mTipsFontSize = Number(Data.getInstance().conf["main.scene.tips.size"] || 12);
			this.mTipsSizeInput.text = String(this.mTipsFontSize);
			this.mTipsSizeInput.addEventListener(FlexEvent.ENTER,
				function (e:FlexEvent):void {
					self.mTipsFontSize = Number(self.mTipsSizeInput.text);
					Data.getInstance().setEditorConfig("main.scene.tips.size", self.mTipsFontSize);
					for each(var item:Component in self.mComponents )
					{
						if ( item as Entity )
							(item as Entity).setTextTipsSize( self.mTipsFontSize );
					}
				}
			);
			
			//
			this.mCoordinator = new Coordinator( );
			this.mCoordinator.y = this.mAdaptiveLayer.height-1;
			this.mCoordinator.x = -1;
			this.mCoordinator.showGrid( this.mShowGrid.selected );
			this.mCoordinator.setMeshDensity( 
				this.mGridWidth, this.mGridHeight, height, this.mProgressInPixel 
			);
			this.setProgress(this.mProgressInPixel);
			this.mCoordinator.addEventListener( MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					if( self.mSelectFrame ) return;
					self.mSelectFrame = new SpriteVisualElement;
					self.mSelectFrame.x = self.mCoordinator.mouseX;
					self.mSelectFrame.y = self.mCoordinator.mouseY-self.mProgressInPixel;
					self.mComponentsLayer.addElement( self.mSelectFrame );
				}
			);
			
			this.mAdaptiveLayer.addElement( this.mCoordinator );
			this.mAdaptiveLayer.setElementIndex( 
				this.mComponentsLayer, this.mAdaptiveLayer.numElements-1 
			);

			this.addEventListener( MouseEvent.MOUSE_MOVE,
				function(e:MouseEvent):void {
					if( self.mFocusComponent ) 
					{
						var inSelected:Boolean = false;
						for each( var item:Component in self.mSelectedComponents )
							if( item == self.mFocusComponent )
							{
								inSelected = true;
								break;
							}
						if( !inSelected ) self.onCancelSelect();
						
						var deltaX:Number = (self.mouseX - self.mDraggingX);
						var deltaY:Number = (self.mouseY - self.mDraggingY);
						
						self.mFocusComponent.x += deltaX;
						self.mFocusComponent.y += deltaY;
						for each( item in self.mSelectedComponents )
						{
							if( item != self.mFocusComponent )
							{
								item.x += deltaX;
								item.y += deltaY;
							}
						}
					
						self.mDraggingX = self.mouseX;
						self.mDraggingY = self.mouseY;
						
						self.mInfoXInput.text = String(self.mFocusComponent.x*2);
						self.mInfoYInput.text = String(-self.mFocusComponent.y*2);
						if( (self.mFocusComponent as Entity) )
						{
							self.mInfoTimeInput.text = String(
								(self.mFocusComponent as Entity).triggeredTime
							);
						}
						
						self.onMonsterChange();
					}
					
					if( !self.mSelectFrame ) return;
					
					self.mSelectFrame.graphics.clear();
					self.mSelectFrame.graphics.lineStyle(1);
					self.mSelectFrame.graphics.drawRect(
						0, 0, 
						self.mCoordinator.mouseX-self.mSelectFrame.x, 
						self.mCoordinator.mouseY-self.mProgressInPixel-self.mSelectFrame.y
					);
					
					if( !e.buttonDown )
					{
						self.mComponentsLayer.removeElement( self.mSelectFrame );
						self.mSelectFrame = null;
					}
				}
			);
			
			this.addEventListener( MouseEvent.MOUSE_UP,
				function(e:MouseEvent):void {
					e.stopPropagation();
					self.mFocusComponent = null;
					
					if( !self.mSelectFrame ) return;
					
					var bound:Rectangle =  self.mSelectFrame.getBounds(self);
					if( (bound.right - bound.left) + (bound.bottom - bound.top) < 50 )
						self.onMouseClick(null);
					else
						self.onSelectMonsters( );
					
					self.mComponentsLayer.removeElement( self.mSelectFrame );
					self.mSelectFrame = null;
				}
			);
			
			this.addEventListener( MouseEvent.MOUSE_WHEEL, onWheelMove );
			this.addEventListener( MouseEvent.MOUSE_MOVE, 
				function(e:MouseEvent):void
				{
					self.mMousePos.text = 
						"鼠标位置：("+int(self.mCoordinator.mouseX)+", "+
									int(-self.mCoordinator.mouseY+self.mProgressInPixel)+")";
									
					if( self.isOutOfCoordinator() && self.mSelectFrame )
					{
						self.mComponentsLayer.removeElement( self.mSelectFrame );
						self.mSelectFrame = null;
					}
					
					self.updateMouseTips();
				}
			);
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			this.addEventListener( ResizeEvent.RESIZE, onResize );
			
			Runtime.getInstance().addEventListener( 
				Runtime.SELECT_DATA_CHANGE, this.onSelectChange
			);
		}
		
		public function save():void
		{			
			if( this.mLevelId ) 
			{
				Data.getInstance().updateLevelDataById( 
					this.mLevelId, this.getMatsData()
				);
				MsgInform.shared().show(this.mRelatedInfo, "保存关卡"+this.mLevelId);
				//Alert.show("【成功】保存关卡"+this.mLevelId);
			}			
		}
		
		public function reset( lid:String ):void
		{
			this.save();
			
			// clean up
			this.mComponents = new Vector.<Component>();
			this.mComponentsLayer.removeAllElements();

			//
			this.mLevelId = lid;
			
			var level:Array = Data.getInstance().getLevelDataById( lid ) as Array;
			if( !level ) level = [];
			
			for each( var item:Object in level )
			{
				var one:Component = this.creator( item.type, this.mTipsFontSize );
				one.unserialize(item);
				this.insertComponent( one, false );
			}
		
			this.onMonsterChange();
		}

		// ------------------------------------------------------------
		// user actions 
		private function onResize( e:ResizeEvent ):void
		{
			var height:Number = this.height - 65;
			this.mComponentsLayer.y 		= this.mProgressInPixel + height;
			this.mAdaptiveLayer.height 	= height;
			this.mCoordinator.y 		= height;
			this.mCoordinator.setMeshDensity( 
				this.mGridWidth, this.mGridHeight, height, this.mProgressInPixel 
			);
		}
		
		private function onWheelMove(e:MouseEvent):void 
		{
			if( e.ctrlKey && this.mComponents.length > 0 ) // scale monsters in y axis 
			{	
				var min:Number = this.mComponents[0].y;
				for each( var item:Component in this.mComponents )
					min = Math.max( min, item.y);
						
				for each( item in this.mComponents )
				{					
					var delta:Number = (item.y-min)*e.delta*0.05;
					
					item.y += delta;
					if( item as Entity )
						(item as Entity).triggeredTime -= (delta*2); 
				}
			}
			else
			{
				//trace( "delta " +e.delta );
				this.setProgress( this.mProgressInPixel + e.delta*this.mGridHeight );
			}
		}
		
		private function onMouseClick(e:MouseEvent):void
		{
			this.onCancelSelect();
			
			var type:String = Runtime.getInstance().selectedComponentType;
			var fid:String = Runtime.getInstance().selectedFormationType;
			
			if( type )
			{
				if( fid )
				{
					var posData:Object = Data.getInstance().getFormationById( fid );
					for each( var p:Object in posData )
					{
						var item:Component = this.creator( type, this.mTipsFontSize );
						
						var gridPos:Point = this.mCoordinator.getPos();
						var size:Point = this.getTipsLayerSize();
						
						item.x 	= p.x + gridPos.x - size.x/2; 
						item.y	= p.y + gridPos.y - this.mProgressInPixel + size.y/2;
						
						if( item.x > 0 && item.x < MainScene.kSCENE_WIDTH/2 )
							this.insertComponent( item, false );
					}
					this.onMonsterChange();
				} else {
					item 	= this.creator( type, this.mTipsFontSize );					
					gridPos = this.mCoordinator.getGridPos();
					if( !this.mRestrictGrid.selected )
						gridPos = this.mCoordinator.getPos();
					
					item.x 	= gridPos.x; 
					item.y	= gridPos.y - this.mProgressInPixel;
					
					if( item.x > 0 && item.x < MainScene.kSCENE_WIDTH/2 )
						this.insertComponent( item );
				}
			}
		}
		
		public function onCancelSelect():void
		{
			if( this.mSelectedComponents )
			{
				for each( var item:Component in this.mSelectedComponents )
				{
					item.select( false );
					item.contextMenu = null;
				}
			}
			
			this.mSelectedComponents = [];
			this.mSelectedBoard.removeAllElements();
			
			this.onPaste( false );
		}
		
		public function onRightClick():void
		{
			this.onPaste( false );
		}
		
		protected function onPaste( v:Boolean ):void
		{			
			this.mReadyToPaste = v;
			this.mSelectionPanel.title = "选中对象("+this.mSelectedComponents.length+") 剪贴板："+
				(this.mReadyToPaste ? "开启":"关闭");
			
			if( this.mPasteTipsLayer )
			{
				this.removeElement( this.mPasteTipsLayer );
				this.mPasteTipsLayer = null;
			}
			
			if( !v ) return;
			this.mPasteTipsLayer = new Group;
			
			this.addElement( this.mPasteTipsLayer );
			this.mPasteTipsLayer.alpha = 0.5;
			
			var self:MainScene = this;
			this.mPasteData = [];
			
			var min_x:Number = this.mSelectedComponents[0].x;
			var max_x:Number = this.mSelectedComponents[0].x;
			
			var min_y:Number = this.mSelectedComponents[0].y;
			var max_y:Number = this.mSelectedComponents[0].y;
			
			for( var i:int=0; i<this.mSelectedComponents.length; i++ )
			{
				var one:Component = this.mSelectedComponents[i];
				min_x = Math.min( min_x, one.x);
				max_x = Math.max( max_x, one.x);
				min_y = Math.min( min_y, one.y);
				max_y = Math.max( max_y, one.y);
			}
			
			for each( var item:Component in this.mSelectedComponents )
			{
				this.mPasteData.push({ 
					pos: new Point(item.x-min_x-(max_x-min_x)/2, item.y-min_y-(max_y-min_y)/2),
					type : item.classId
				});
					
				var mat:Component = this.creator( item.classId, 0 );
				mat.x = this.mPasteData[this.mPasteData.length-1].pos.x;
				mat.y = this.mPasteData[this.mPasteData.length-1].pos.y;
				mat.addEventListener(MouseEvent.CLICK, function(e:*):void {
					self.onMouseClick(e);
				});
				if( mat as Entity ) (mat as Entity).setBaseSize( 50 );
				
				mPasteTipsLayer.addElement(mat);
			}
		}
		
		private function onChangeSelectedType( type:String ):void
		{
			if( !Data.getInstance().getEnemyProfileById( Runtime.getInstance().currentLevelID, type ) )
			{
				Alert.show("【错误】无法识别的类型id，请检查后重新填写");
				return;
			}
			
			//trace( this.mSelectedMonsters.length );
			var monsters:Array = [];
			for each( var item:Component in this.mSelectedComponents )
			{
				//trace( item.type +" -> "+ type);
				var one:Component = this.creator( type, this.mTipsFontSize );
				one.x = item.x;
				one.y = item.y;
				this.insertComponent( one, false );
			}
			this.onMonsterChange();
			
			this.onDeleteSelectedMonsters();
			for each( item in monsters )
				this.selectComponent( item );
		}
		
		private static const kSELECTED_BOARD_UNIT_WIDTH:int 	= 50;
		private static const kSELECTED_BOARD_UNIT_HEIGHT:int 	= 50;
		private static const kSELECTED_BOARD_COLUMS:int 		= 3;
		private function selectComponent( item:Component ):void
		{
			if( this.mSelectedComponents.hasOwnProperty(item.globalId) ) return;
			
			var self:MainScene = this;
				
			for each ( var t:Component in this.mSelectedComponents )
				if( t == item ) return;

			// update selected monsters in scene
			item.select( true );
			this.mSelectedComponents.push(item);
			this.mComponentsLayer.setElementIndex(item, this.mComponentsLayer.numElements-1);
			
			var menu:ContextMenu = new ContextMenu;
			
			var changeType:ContextMenuItem = new ContextMenuItem("更换敌人");
			changeType.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT,
				function(e:ContextMenuEvent):void {
					var enemies:Object = Data.getInstance().getEnemiesByLevelId( self.mLevelId );
					var data:Array = [];
					for each( var item:* in enemies )
					{
						data.push(
							{
								label:item.monster_id+"|"+item.monster_name,
								type:item.monster_id
							}
						);
					}
					
					Utils.makeComboboxPanel(function(ind:int):void
					{
						if( ind < 0 ) return;
						self.onChangeSelectedType( data[ind].type );
					}, self, data, "请选择");
				}
			);
			
			var formation:ContextMenuItem = new ContextMenuItem("设为阵型");
			formation.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
				function(e:ContextMenuEvent):void {
					self.makeSelectMonstersToFormation();
				}
			);
			
			var erase:ContextMenuItem = new ContextMenuItem("删除");
			erase.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
				function(e:ContextMenuEvent):void{
					self.onDeleteSelectedMonsters();
				}
			);
			
			menu.addItem( changeType );
			menu.addItem( formation );
			menu.addItem( erase );
			item.contextMenu = menu;
			
			// update information panel
			if( item.classId == AreaTrigger.TRIGGER_TYPE )
			{
				this.mInfoId.text = "ID:   " + String(item.classId);
				this.mInfoName.text = "NAME: ";
			} else {
				this.mInfoId.text = "ID:   " + String(item.classId);
				this.mInfoName.text = "NAME: " + 
					String( Data.getInstance().getEnemyProfileById( 
						Runtime.getInstance().currentLevelID, item.classId 
					).monster_name );
			}
			this.mInfoXInput.text = String(item.x*2);
			this.mInfoYInput.text = String(-item.y*2);
			if( item as Entity )
				this.mInfoTimeInput.text = String( (item as Entity).triggeredTime );
			else 
				this.mInfoTimeInput.text = String( -1 );
			
			// update board of monsters
			var index:int = this.mSelectedBoard.numElements;
			var row:int = index / MainScene.kSELECTED_BOARD_COLUMS;
			var col:int = index % MainScene.kSELECTED_BOARD_COLUMS;
			
			var one:Component = this.creator( item.classId, 8 );
			one.x = 30 + col*MainScene.kSELECTED_BOARD_UNIT_WIDTH;
			one.y = 40 + row*MainScene.kSELECTED_BOARD_UNIT_HEIGHT;
			if( one as Entity )
			{
				(one as Entity).setSize(20);
			}else{ 
				one.y -= MainScene.kSELECTED_BOARD_UNIT_HEIGHT/2;
				one.setBaseSize( 30 );
			}
			this.mSelectedBoard.addElement( one );
			
			this.onPaste( false );
		}
		
		private function selectMonstersByType( type:String ):void
		{
			this.onCancelSelect();
			
			for each( var m:Component in this.mComponents )
				if( m.classId == type ) this.selectComponent( m );
				
			if( type == AreaTrigger.TRIGGER_TYPE )
			{
				this.mInfoId.text = "ID:   " + String(type);
				this.mInfoName.text = "NAME: ";
			} else {
				this.mInfoId.text = "ID:   " + String(type);
				this.mInfoName.text = "NAME: " + 
					String( Data.getInstance().getEnemyProfileById( 
						Runtime.getInstance().currentLevelID, type
					).monster_name );
			}
			if( this.mSelectedComponents.length > 1 )
			{
				this.mInfoXInput.text 		= "";
				this.mInfoYInput.text 		= "";
				this.mInfoTimeInput.text 	= "";
			}
		}
		
		private function onSelectMonsters( ):void
		{
			//trace("onSelectMonsters");
			this.onCancelSelect();
			
			var frame:Rectangle = this.mSelectFrame.getBounds( this );
			for each( var m:Component in this.mComponents )
			{
				var bound:Rectangle = m.getBounds( this );
				if( frame.intersects(bound) )
					this.selectComponent( m );
			}
			
			if( this.mSelectedComponents.length > 1 )
			{
				this.mInfoId.text 			= "ID:   ";
				this.mInfoName.text  		= "NAME: ";
				this.mInfoXInput.text 		= "";
				this.mInfoYInput.text 		= "";
				this.mInfoTimeInput.text 	= "";
			}
		}
		
		private function onDeleteSelectedMonsters() :void
		{
			for( var i:int=this.mComponents.length-1; i>=0; i-- )
			{
				for each( var sm:Component in this.mSelectedComponents )
				{
					if( this.mComponents[i] == sm ) 
					{
						sm.dtor();
						this.mComponentsLayer.removeElement( sm );
						this.mComponents.splice(i, 1);
						break;
					}
				}
			}
			
			this.onCancelSelect();
			this.onMonsterChange();
		}
		
		// ------------------------------------------------------------
		private function setProgress( progress:Number ):void
		{
			progress = Math.max( progress, 0 );
			this.mProgressInPixel = progress;
			this.mComponentsLayer.y = this.mProgressInPixel + this.height - 65;
			this.mCoordinator.setMeshDensity( 
				this.mGridWidth, this.mGridHeight, this.height-65, this.mProgressInPixel 
			);
			
			this.mTimeline.value = this.mProgressInPixel /this.mMapSpeed;
			this.mNowTimeLabel.text = "当前时间："+Utils.getTimeFormat(this.mTimeline.value);
		}
		
		private function onMonsterChange():void
		{
			var max:Number = 0;
			if( this.mComponents.length > 0 )
			{
				max = this.mComponents[0].y;
				for each( var m:Component in this.mComponents )
					max = Math.min( m.y, max );
			} 
			
			this.mFinishingLine = -max;
			this.mTimeline.maximum = -max / this.mMapSpeed;
			
			this.mTotalMonsters.text = "实体数量："+this.mComponents.length;
			this.mMapLength.text = "地图长度："+Utils.getTimeFormat(this.mFinishingLine/this.mMapSpeed);
		}
		
		private var mDraggingX:Number = -1;
		private var mDraggingY:Number = -1;
		private static var gComponentCountor:int = 0;
		private function insertComponent( item:Component, save:Boolean = true ):void
		{	
			if( item.globalId == "" || !item.globalId )
				item.globalId = new Date().time+String( gComponentCountor++ );
			
			if( item as AreaTrigger )
				(item as AreaTrigger).enableEditing( this );
			else if( item as Entity )
				(item as Entity).setBaseSize( 50 );
			
			this.mComponents.push( item );
			this.mComponentsLayer.addElement( item );
		
			var self:MainScene = this;
			var timer:Timer = new Timer(300, 1);
			var clickTimer:Timer = new Timer(100, 1);
			item.addEventListener( MouseEvent.CLICK,
				function(e:MouseEvent) : void {
					if( timer.running ) {
						timer.stop();
						self.selectMonstersByType( item.classId );
					} else {
						timer.start();
						
						if( clickTimer.running )
						{
							if( !e.shiftKey )
								self.onCancelSelect();
							self.selectComponent( item );
						}
						clickTimer.stop();
					}
				}
			);
			
			item.addEventListener( MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent) : void {
					clickTimer.start();
					self.mFocusComponent = item;
					self.mDraggingX = self.mouseX;
					self.mDraggingY = self.mouseY;
				}
			);
			
			if( save ) this.onMonsterChange();
		}
//		
		private function onKeyDown(e:KeyboardEvent):void
		{
//			e.stopPropagation();
			var code:uint = e.keyCode;
			if( code == Keyboard.V && e.ctrlKey )
			{
				if( !this.mReadyToPaste ) return;
				
				//Utils.dumpObject( this.mPasteData );
				for each( var monster:* in this.mPasteData )
				{
					var one:Component = this.creator( monster.type, this.mTipsFontSize );
					one.x = monster.pos.x + this.mComponentsLayer.mouseX;
					one.y = monster.pos.y + this.mComponentsLayer.mouseY;
					this.insertComponent( one, false );
				}
				this.onMonsterChange();
			}
			else if( code == Keyboard.C && e.ctrlKey )
			{
				this.onPaste(true);
			}
			else if( code == Keyboard.S && e.ctrlKey )
			{
				this.save();
			}
			else if( code == Keyboard.D && e.ctrlKey )
			{  
				this.onDeleteSelectedMonsters();
			}
			else if( code == Keyboard.LEFT )
			{
				for each( var item:* in this.mSelectedComponents )
				{
					if( this.mRestrictGrid.selected )
						item.x -= Number(this.mGridWidthInput.text)
					else
						item.x -= 1;			
				}
			}
			else if( code == Keyboard.RIGHT )
			{
				for each( item in this.mSelectedComponents )
				{
					if( this.mRestrictGrid.selected )
						item.x += Number(this.mGridWidthInput.text)
					else
						item.x += 1;
				}
			}
			else if( code == Keyboard.UP )
			{
				for each( item in this.mSelectedComponents )
				{
					if( this.mRestrictGrid.selected )
						item.y -= Number(this.mGridHeightInput.text)
					else
						item.y -= 1;
				}
			}			
			else if( code == Keyboard.DOWN )
			{
				for each( item in this.mSelectedComponents )
				{
					if( this.mRestrictGrid.selected )
						item.y += Number(this.mGridHeightInput.text)
					else
						item.y += 1;;	
				}
			}
			
			if( this.mRestrictGrid.selected &&
				( code == Keyboard.UP || code == Keyboard.LEFT || 
				  code == Keyboard.DOWN || code == Keyboard.RIGHT ) )
			{
				for each( item in this.mSelectedComponents )
				{
					var now:Point = this.mCoordinator.getGridPos( item.x, item.y );
					item.x = now.x;
					item.y = now.y;	
				}
			}
		}
		
		private var mSelectType:String 		= null;
		private var mSelectFormation:String = null;
		private function onSelectChange(e:Event):void 
		{
			this.onPaste( false );
			
			if( (this.mSelectType != Runtime.getInstance().selectedComponentType ||
				 this.mSelectFormation != Runtime.getInstance().selectedFormationType) 
				&& this.mSelectedTipsLayer )
			{
				this.removeElement( this.mSelectedTipsLayer );
				this.mSelectedTipsLayer = null;
			}
			
			this.mSelectedTipsLayer = new Group;
			
			this.addElement( this.mSelectedTipsLayer );
			this.mSelectedTipsLayer.alpha = 0.5;
			
			var self:MainScene = this;
			this.mSelectType = Runtime.getInstance().selectedComponentType;
			this.mSelectFormation = Runtime.getInstance().selectedFormationType;
			if( this.mSelectType ) 
			{
				if( this.mSelectFormation )
				{
					var posData:Object = Data.getInstance().getFormationById( this.mSelectFormation );
					for each(var p:* in posData)
					{
						var mat:Component = this.creator( this.mSelectType, 0 );
						mat.x = p.x;
						mat.y = p.y;
						mat.addEventListener(MouseEvent.CLICK, function(e:*):void {
							self.onMouseClick(e);
						});
						if( mat as Entity )
							(mat as Entity).setBaseSize( 50 );
						mSelectedTipsLayer.addElement(mat);
					}
				}
				else 
				{
					var mat2:Component = this.creator( this.mSelectType, 0 );
					mat2.addEventListener(MouseEvent.CLICK, function(e:*):void {
						self.onMouseClick(e);
					});
					if( mat2 as Entity )
						(mat2 as Entity).setBaseSize( 50 );
					mSelectedTipsLayer.addElement(mat2);
				}
			}
		}
		private function updateMouseTips():void
		{
			if(this.mSelectedTipsLayer)
			{
				if( this.mSelectFormation )
				{
					var size:Point = this.getTipsLayerSize();
					this.mSelectedTipsLayer.x = this.mouseX - size.x/2;
					this.mSelectedTipsLayer.y = this.mouseY + size.y/2;
				} else {
					this.mSelectedTipsLayer.x = this.mouseX;
					this.mSelectedTipsLayer.y = this.mouseY;	
				}
			}
			
			if( this.mPasteTipsLayer )
			{
				//size = this.getPasteTipsLayerSize();
				size = new Point();
				this.mPasteTipsLayer.x = this.mouseX - size.x/2;
				this.mPasteTipsLayer.y = this.mouseY + size.y/2;
			}
		}
		
		// ------------------------
		// facilities
		private function creator( type:String, fontSize:Number ):Component
		{
			if( type == AreaTrigger.TRIGGER_TYPE )
				return new AreaTrigger( );
			else 
			{
				var ret:Entity =  new Entity( type, true );
				ret.setBaseSize( 50 );
				ret.setTextTipsSize( fontSize );
				return ret;
			}
		}
		
		private function getSelectedComponentsSize():Point
		{
			if( this.mSelectedComponents && this.mSelectedComponents.length > 0 )
			{
				var min_x:Number = this.mSelectedComponents[0].x;
				var max_x:Number = this.mSelectedComponents[0].x;
				
				var min_y:Number = this.mSelectedComponents[0].y;
				var max_y:Number = this.mSelectedComponents[0].y;
				
				for( var i:int=0; i<this.mSelectedComponents.length; i++ )
				{
					var item:IVisualElement = this.mSelectedComponents[i];
					min_x = Math.min( min_x, item.x);
					max_x = Math.max( max_x, item.x);
					min_y = Math.min( min_y, item.y);
					max_y = Math.max( max_y, item.y);
				}
				
				return new Point( Math.abs( max_x - min_x ), Math.abs( max_y - min_y ) );
			} else 
				return new Point();
		}
		
		private function getTipsLayerSize():Point 
		{
			if( this.mSelectedTipsLayer && this.mSelectedTipsLayer.numElements > 0 )
			{
				var min_x:Number = this.mSelectedTipsLayer.getElementAt(0).x;
				var max_x:Number = this.mSelectedTipsLayer.getElementAt(0).x;
				
				var min_y:Number = this.mSelectedTipsLayer.getElementAt(0).y;
				var max_y:Number = this.mSelectedTipsLayer.getElementAt(0).y;
				
				for( var i:int=0; i<this.mSelectedTipsLayer.numElements; i++ )
				{
					var item:IVisualElement = this.mSelectedTipsLayer.getElementAt(i);
					min_x = Math.min( min_x, item.x);
					max_x = Math.max( max_x, item.x);
					min_y = Math.min( min_y, item.y);
					max_y = Math.max( max_y, item.y);
				}

				return new Point( Math.abs( max_x - min_x ), Math.abs( max_y - min_y ) );
			} else 
				return new Point();
		}
		
		private function getPasteTipsLayerSize():Point
		{
			if( this.mPasteTipsLayer && this.mPasteTipsLayer.numElements > 0 )
			{
				var min_x:Number = this.mPasteTipsLayer.getElementAt(0).x;
				var max_x:Number = this.mPasteTipsLayer.getElementAt(0).x;
				
				var min_y:Number = this.mPasteTipsLayer.getElementAt(0).y;
				var max_y:Number = this.mPasteTipsLayer.getElementAt(0).y;
				
				for( var i:int=0; i<this.mPasteTipsLayer.numElements; i++ )
				{
					var item:IVisualElement = this.mPasteTipsLayer.getElementAt(i);
					min_x = Math.min( min_x, item.x);
					max_x = Math.max( max_x, item.x);
					min_y = Math.min( min_y, item.y);
					max_y = Math.max( max_y, item.y);
				}
				
				return new Point( Math.abs( max_x - min_x ), Math.abs( max_y - min_y ) );
			} else 
				return new Point();
		}
		
		private function getMatsData():Array
		{
			var data:Array = new Array;
			for each(var m:Component in this.mComponents)
			{
				data.push(m.serialize());
			}
			return data;
		}
		
		private function getMat(sid:String):Component
		{
			for each(var m:Component in this.mComponents)
				if(m.globalId == sid)
					return m;
			return null;
		}
		
		private function isOutOfCoordinator():Boolean
		{
			var x:int = this.mouseX;
			var y:int = this.mouseY;
			
			if( x < 0 || y < 0 ) return true;
			if( x >= this.width ) return true;
			if( y >= this.height ) return true;
			
			return false;
		}
		
		private function makeSelectMonstersToFormation():void
		{
			if( !this.mSelectedComponents || this.mSelectedComponents.length <= 0 )
				return;

			var self:MainScene = this;
			Utils.makeRenamePanel(
				function( ret:String = null ):void {
					if( !ret ) return;
					var formation:* = Data.getInstance().getFormationById( ret )
					if( formation ) 
						Alert.show("【错误】该阵型名已经存在!");
					else
					{
						Data.getInstance().updateFormationSetById( 
							ret, format(self.mSelectedComponents) 
						);
					}
				}, this
			);
		}
		
		private function format(mats:Array):Array
		{
			var data:Array = new Array;
			var minX:Number = mats[0].x;
			var minY:Number = mats[0].y;
			for each(var m:Entity in mats)
			{
				minX = Math.min(m.x, minX);
				minY = Math.max(m.y, minY);
				
				var point:Object = new Object;
				point.x = m.x;
				point.y = m.y;
				data.push(point);
			}
			for each(var p:* in data)
			{
				p.x -= minX;
				p.y -= minY;
			}
			return data;
		}
		
		public function hasMonsterCaputuredByTrigger( sid:String ):Boolean
		{
			for each( var m:Component in this.mComponents )
			{
				var ati:AreaTrigger = m as AreaTrigger;
				if( !ati ) continue;
				if( ati.isMonsterIn( sid ) ) return true;
			}
			return false;
		}
		
		public function getMonsterByPoint( pos:Point ):Entity
		{
			var local:Point = this.mComponentsLayer.globalToLocal(pos);
			for each( var m:Component in this.mComponents )
			{
				var em:Entity = m as Entity;
				if( !em ) continue;
				
				var bound:Rectangle = em.getBounds( this.mComponentsLayer );
				if( bound.contains( local.x, local.y ) )
				{
					return em;
				}
			}
			return null;
		}
		
		public function getMonsterBySID( sid:String ):Entity
		{
			for each( var item:Component in this.mComponents )
			{
				var em:Entity = item as Entity;
				if( em && em.globalId == sid ) return em; 
			}
			return null;
		}
	}
} 