/*
this view contains the map,the time scroller, the inputform.
*/
package 
{
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.events.SliderEvent;
	
	import spark.components.Group;
	import spark.core.SpriteVisualElement;
	
	import mapEdit.AreaTriggerComponent;
	import mapEdit.Component;
	import mapEdit.Coordinator;
	import mapEdit.EditMatsControl;
	import mapEdit.EntityComponent;
	import mapEdit.MainSceneXML;
	import mapEdit.MatFactory;
	
	public class MainScene extends MainSceneXML
	{
		[Embed(source="map_snow1.png")]
		static public var BgImage:Class;
		
		public static const kSCENE_WIDTH:Number = 720;
		public static const kSCENE_HEIGHT:Number = 1280;
		
		private var mLevelId:String 				= null;
		
		private var mMonsters:Vector.<Component> 	= null;
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
		private var mSelectFrame:SpriteVisualElement 	= null;
		private var mSelectedMonsters:Array 			= [];
		private var mFocusMonster:Component 			= null;
		
		// facilities
		private var mAutoSaver:Timer = null;
		
		public function MainScene()
		{
			with( this ) {
				percentWidth = 100; percentHeight = 100;
			}
			
			var s:* = Data.getInstance().conf.mapSpeed;
			if( s && s>0 ) this.mMapSpeed = s;
			
			var w:* = Data.getInstance().conf.gridWidth;
			if( w && w>0 ) this.mGridWidth = w;
			
			var h:* = Data.getInstance().conf.gridHeight;
			
			var self:MainScene = this;
			this.mAutoSaver = new Timer(5000, 1);
			this.mAutoSaver.addEventListener(TimerEvent.TIMER,
				function(e:TimerEvent) : void {
					self.mAutoSaver.reset();
					self.mAutoSaver.start();
					
					if( self.mLevelId )
					{
						Data.getInstance().updateLevelDataById( 
							self.mLevelId, { data:self.getMatsData() }
						);
					}
				}
			);
			this.mAutoSaver.start();
		}
		
		// ------------------------------------------------------------
		// public operations 
		public function init():void 
		{
			var self:MainScene = this;
			this.mTimeline.addEventListener( SliderEvent.CHANGE, 
				function( e:SliderEvent ): void {
					self.setProgress( e.value * self.mMapSpeed );
				}
			);
			
			this.mCoordinator = new Coordinator( );
			this.mAdaptiveLayer.addElement( this.mCoordinator );
			
			this.mMonsterMask = new SpriteVisualElement();
			this.mAdaptiveLayer.setElementIndex( 
				this.mMonsterLayer, this.mAdaptiveLayer.numElements-1 
			);
			//this.setChildIndex( this.mMonsterLayer, this.numChildren-1);
			//this.addElement( this.mMonsterMask );
			//this.mMonsterLayer.mask = this.mMonsterMask;
			
			// configs
			this.mMapSpeedInput.text 	= String(this.mMapSpeed);
			this.mMapSpeedInput.addEventListener( FlexEvent.ENTER,
				function (e:FlexEvent):void {
					self.mMapSpeed = int(self.mMapSpeedInput.text);
					Data.getInstance().setEditorConfig("mapSpeed", self.mMapSpeed);
				}
			);
			
			this.mShowGrid.addEventListener( Event.CHANGE, 
				function (e:Event):void {
					self.mCoordinator.showGrid( self.mShowGrid.selected );	
					self.mCoordinator.setMeshDensity( 
						self.mGridWidth, self.mGridHeight, self.height-65, self.mProgressInPixel 
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
					if( self.mSelectedMonsters.length == 1 )
					{
						self.mSelectedMonsters[0].x = int(self.mInfoXInput.text)/2;
						self.onMonsterChange();
					}
				}
			);
			
			this.mInfoYInput.addEventListener( FlexEvent.ENTER,
				function (e:FlexEvent):void {
					if( self.mSelectedMonsters.length == 1 )
					{
						self.mSelectedMonsters[0].y = -int(self.mInfoYInput.text)/2;
						self.onMonsterChange();
					}
				}
			);	
			
			this.mInfoTimeInput.addEventListener( FlexEvent.ENTER,
				function (e:FlexEvent):void {
					for each( var item:Component in self.mSelectedMonsters )
					{
						item.triggerTime = int(self.mInfoTimeInput.text);
						if( item as EntityComponent )
							(item as EntityComponent).showTrigger();
					}
					self.onMonsterChange();
				}
			);	
			
			// selection
			this.mCoordinator.addEventListener( MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					if( self.mSelectFrame ) return;
					self.mSelectFrame = new SpriteVisualElement;
					self.mSelectFrame.x = self.mCoordinator.mouseX;
					self.mSelectFrame.y = self.mCoordinator.mouseY-self.mProgressInPixel;
					self.mMonsterLayer.addElement( self.mSelectFrame );
				}
			);

			this.addEventListener( MouseEvent.MOUSE_MOVE,
				function(e:MouseEvent):void {
					if( self.mFocusMonster ) 
					{
						var deltaX:Number = (self.mouseX - self.mDraggingX);
						var deltaY:Number = (self.mouseY - self.mDraggingY);
						
						self.mFocusMonster.x += deltaX;
						self.mFocusMonster.y += deltaY;
						for each( var item:Component in self.mSelectedMonsters )
						{
							if( item != self.mFocusMonster )
							{
								item.x += deltaX;
								item.y += deltaY;
							}
						}
					
						self.mDraggingX = self.mouseX;
						self.mDraggingY = self.mouseY;
						
						self.mInfoXInput.text = String(self.mFocusMonster.x*2);
						self.mInfoYInput.text = String(-self.mFocusMonster.y*2);
						self.mInfoTimeInput.text = String(self.mFocusMonster.triggerTime);
						
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
						self.mMonsterLayer.removeElement( self.mSelectFrame );
						self.mSelectFrame = null;
					}
				}
			);
			
			this.addEventListener( MouseEvent.MOUSE_UP,
				function(e:MouseEvent):void {
					self.mFocusMonster = null;
					
					if( !self.mSelectFrame ) return;
					
					var bound:Rectangle =  self.mSelectFrame.getBounds(self);
					if( (bound.right - bound.left) + (bound.bottom - bound.top) < 50 )
						self.onMouseClick(null);
					else
						self.onSelectMonsters( );
					
					self.mMonsterLayer.removeElement( self.mSelectFrame );
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
						self.mMonsterLayer.removeElement( self.mSelectFrame );
						self.mSelectFrame = null;
					}
					
					self.updateMouseTips();
				}
			);
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
					this.mLevelId, { data:this.getMatsData() }
				);
			}			
		}
		public function reset( lid:String ):void
		{
			this.save();
			
			// clean up
			this.mMonsters = new Vector.<Component>();
			this.mMonsterLayer.removeAllElements();

			//
			this.mLevelId = lid;
			
			var level:Object = Data.getInstance().getLevelDataById( lid );
			if( !level ) level = { data:[] };
			
			for each( var item:Object in level.data )
			{
				var one:Component = this.creator( item.type );			
				one.initFromData(item);
				if( item.x > 0 && item.x < MainScene.kSCENE_WIDTH )
					this.insertMonster( one, false );
			}
			
			this.onMonsterChange();
		}

		// ------------------------------------------------------------
		// user actions 
		private function onResize( e:ResizeEvent ):void
		{
			var height:Number = this.height - 65;
			this.mMonsterMask.graphics.clear();
			this.mMonsterMask.graphics.beginFill(0xffffff);
			this.mMonsterMask.graphics.drawRect(-180, -height, 360, height);
			this.mMonsterMask.graphics.endFill();
			this.mMonsterMask.height 	= height;
			this.mMonsterLayer.y 		= this.mProgressInPixel + height;
			this.mAdaptiveLayer.height 	= height;
			this.mCoordinator.y 		= height;
			this.mCoordinator.setMeshDensity( 
				this.mGridWidth, this.mGridHeight, height, this.mProgressInPixel 
			);
		}
		
		private function onWheelMove(e:MouseEvent):void 
		{
			if( e.ctrlKey && this.mMonsters.length > 0 ) // scale monsters in y axis 
			{
				var min:Number = this.mMonsters[0].y;
				for each( var m:Component in this.mMonsters )
					min = Math.max( m.y, min );
				
				for each( var m2:Component in this.mMonsters )
				{
//					if( m2.triggerTime >= 0 ) {
//						trace( m2.y - m2.triggerTime );
//						var delta:int = m2.y - m2.triggerTime;
//						m2.y = min + (m2.y-min) * (1+e.delta*0.05);
//						m2.triggerTime = m2.y - delta;
//						trace( m2.y - m2.triggerTime );
//					} else 
						m2.y = min + (m2.y-min) * (1+e.delta*0.05);
				}
			}else
				this.setProgress( this.mProgressInPixel + e.delta*this.mGridHeight );
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
						var item:Component = this.creator( type );
						item.x 	= p.x + this.mCoordinator.mouseX; 
						item.y	= p.y + this.mCoordinator.mouseY - this.mProgressInPixel; 
						if( item.x > 0 && item.x < MainScene.kSCENE_WIDTH/2 )
							this.insertMonster( item, false );
					}
					this.onMonsterChange();
				} else {
					item = this.creator( type );
					item.x 	= this.mCoordinator.mouseX; 
					item.y	= this.mCoordinator.mouseY - this.mProgressInPixel; 
					if( item.x > 0 && item.x < MainScene.kSCENE_WIDTH/2 )
						this.insertMonster( item );
				}
			}
		}
		
		public function onCancelSelect():void
		{
			if( this.mSelectedMonsters )
			{
				for each( var item:Component in this.mSelectedMonsters )
				{
					item.select( false );
					item.contextMenu = null;
				}
			}
			
			this.mSelectedMonsters = [];
			this.mSelectedBoard.removeAllElements();
		}
		
		private static const kSELECTED_BOARD_UNIT_WIDTH:int 	= 50;
		private static const kSELECTED_BOARD_UNIT_HEIGHT:int 	= 50;
		private static const kSELECTED_BOARD_COLUMS:int 		= 3;
		private function selectMonster( item:Component ):void
		{
			var self:MainScene = this;
			
			// update selected monsters in scene
			item.select( true );
			this.mSelectedMonsters.push(item);
			this.mMonsterLayer.setElementIndex(item, this.mMonsterLayer.numElements-1);
			
			var menu:ContextMenu = new ContextMenu;
			
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
			
			menu.addItem( formation );
			menu.addItem( erase );
			item.contextMenu = menu;
			
			// update information panel
			this.mInfoXInput.text = String(item.x*2);
			this.mInfoYInput.text = String(-item.y*2);
			this.mInfoTimeInput.text = String(item.triggerTime);
			
			// update board of monsters
			var index:int = this.mSelectedBoard.numElements;
			var row:int = index / MainScene.kSELECTED_BOARD_COLUMS;
			var col:int = index % MainScene.kSELECTED_BOARD_COLUMS;
			
			var one:Component = this.creator( item.type );
			one.trim(40);
			one.x = 30 + col*MainScene.kSELECTED_BOARD_UNIT_WIDTH;
			one.y = 40 + row*MainScene.kSELECTED_BOARD_UNIT_HEIGHT;
			this.mSelectedBoard.addElement( one );
		}
		
		private function selectMonstersByType( type:String ):void
		{
			this.onCancelSelect();
			
			for each( var m:Component in this.mMonsters )
				if( m.type == type ) this.selectMonster( m );
			
			if( this.mSelectedMonsters.length > 1 )
			{
				this.mInfoXInput.text 		= "";
				this.mInfoYInput.text 		= "";
				this.mInfoTimeInput.text 	= "";
			}
		}
		
		private function onSelectMonsters( ):void
		{
			this.onCancelSelect();
			
			var frame:Rectangle = this.mSelectFrame.getBounds( this );
			for each( var m:Component in this.mMonsters )
			{
				var bound:Rectangle = m.getBounds( this );
				if( frame.intersects(bound) )
					this.selectMonster( m );
			}
			
			if( this.mSelectedMonsters.length > 1 )
			{
				this.mInfoXInput.text 		= "";
				this.mInfoYInput.text 		= "";
				this.mInfoTimeInput.text 	= "";
			}
		}
		
		private function onDeleteSelectedMonsters() :void
		{
			for( var i:int=this.mMonsters.length-1; i>=0; i-- )
			{
				for each( var sm:Component in this.mSelectedMonsters )
				{
					if( this.mMonsters[i] == sm ) 
					{
						this.mMonsterLayer.removeElement( sm );
						this.mMonsters.splice(i, 1);
						break;
					}
				}
			}
			
			this.onMonsterChange();
		}
		
		// ------------------------------------------------------------
		private function setProgress( progress:Number ):void
		{
			if( progress < 0 ) return;
			this.mProgressInPixel = progress;
			this.mMonsterLayer.y = this.mProgressInPixel + this.height - 65;
			this.mCoordinator.setMeshDensity( 
				this.mGridWidth, this.mGridHeight, this.height-65, this.mProgressInPixel 
			);
			
			this.mTimeline.value = this.mProgressInPixel /this.mMapSpeed;
			this.mNowTimeLabel.text = "当前时间："+Utils.getTimeFormat(this.mTimeline.value);
		}
		
		private function onMonsterChange():void
		{
			var max:Number = this.mMonsters[0].y;
			for each( var m:Component in this.mMonsters )
			max = Math.min( m.y, max );
			
			this.mFinishingLine = -max;
			this.mTimeline.maximum = -max / this.mMapSpeed;
			
			this.mTotalMonsters.text = "实体数量："+this.mMonsters.length;
			this.mMapLength.text = "地图长度："+Utils.getTimeFormat(this.mFinishingLine/this.mMapSpeed);
			
//			Data.getInstance().updateLevelDataById( 
//				this.mLevelId, { data:this.getMatsData() }
//			);
		}
		
		private var mDraggingX:Number = -1;
		private var mDraggingY:Number = -1;
		private static var gMonsterCountor:int = 0;
		private function insertMonster( item:Component, save:Boolean = true ):void
		{
			if( item.sid == "" || !item.sid ) 
				item.sid = new Date().time+String( gMonsterCountor++ );
			
			this.mMonsterLayer.addElement( item );
			this.mMonsters.push( item );
			
			var self:MainScene = this;
		
			var timer:Timer = new Timer(300, 1);
			item.addEventListener( MouseEvent.CLICK,
				function(e:MouseEvent) : void {
					if( timer.running ) {
						timer.stop();
						self.selectMonstersByType( item.type );
					} else {
						timer.start();
						if( self.mSelectedMonsters.length <= 1 )
						{
							self.onCancelSelect();
							self.selectMonster( item );
						}
					}
				}
			);
			
			item.addEventListener( MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent) : void {
					self.mFocusMonster = item;
					self.mDraggingX = self.mouseX;
					self.mDraggingY = self.mouseY;
				}
			);
			
			if( save ) this.onMonsterChange();
		}
//		
		private function onKeyDown(e:KeyboardEvent):void
		{
//			var code:uint = e.keyCode;
//			if(code == Keyboard.C && e.ctrlKey && selectControl.targets.length > 0)
//			{
//				selectControl.copySelect();
//			}
//			if(code == Keyboard.F && e.ctrlKey && selectControl.targets.length > 0)
//			{
//				selectControl.setSelectMatToFormation();
//			}
//			if(code == Keyboard.DELETE && selectControl.targets.length > 0)
//			{
//				var copy:Array = selectControl.targets.slice(0, selectControl.targets.length);
//				for each(var m:Component in copy)
//				{
//					matsControl.remove(m.sid);
//				}
//			}
		}
		
		private var mSelectType:String 		= null;
		private var mSelectFormation:String = null;
		private function onSelectChange(e:Event):void 
		{
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
			
			this.mSelectType = Runtime.getInstance().selectedComponentType;
			this.mSelectFormation = Runtime.getInstance().selectedFormationType;
			if( this.mSelectType ) 
			{
				if( this.mSelectFormation )
				{
					var posData:Object = Data.getInstance().getFormationById( this.mSelectFormation );
					for each(var p:* in posData)
					{
						var mat:Component = MatFactory.createMat(this.mSelectType);
						mat.x = p.x;
						mat.y = p.y;
						mSelectedTipsLayer.addElement(mat);
					}
				}
				else 
				{
					var mat2:Component = MatFactory.createMat(this.mSelectType);
					mSelectedTipsLayer.addElement(mat2);
				}
			}
			
		}
		private function updateMouseTips():void
		{
			if(this.mSelectedTipsLayer)
			{
				this.mSelectedTipsLayer.x = this.mouseX-1;
				this.mSelectedTipsLayer.y = this.mouseY-1;
			}
		}
		
		// ------------------------
		// facilities
		private function creator( type:String ):Component
		{
			if( type == AreaTriggerComponent.TRIGGER_TYPE )
				return new AreaTriggerComponent( this );
			else 
				return new EntityComponent( this, type, -1, 30 );
		}
		
		private function getMatsData():Array
		{
			var data:Array = new Array;
			for each(var m:Component in this.mMonsters)
			{
				if(m.triggerId.length > 0 && !getMat(m.triggerId))
					m.triggerId = "";
				
				data.push(m.toExportData());
			}
			return data;
		}
		
		private function getMat(sid:String):Component
		{
			for each(var m:Component in this.mMonsters)
				if(m.sid == sid)
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
			if( !this.mSelectedMonsters || this.mSelectedMonsters.length <= 0 )
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
							ret, format(self.mSelectedMonsters) 
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
			for each(var m:EntityComponent in mats)
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
	}
} 