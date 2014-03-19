/*
this view contains the map,the time scroller, the inputform.
*/
package 
{

	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.ui.Keyboard;
	
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
	import mapEdit.SelectControl;
	
	public class MainScene extends MainSceneXML
	{
		[Embed(source="map_snow1.png")]
		static public var BgImage:Class;
		
		public var matsControl:EditMatsControl;
		
		public static const kSCENE_WIDTH:Number = 720;
		public static const kSCENE_HEIGHT:Number = 1280;
		
		
		private var mMonsters:Vector.<Component> 		= null;
		//private var mMonsterLayer:Group 				= null;
		private var mMonsterMask:SpriteVisualElement 	= null;
		
		private var mProgressInPixel:Number = 0;
		private var mFinishingLine:Number = 0;
		
		private var mSelectedTipsLayer:Group = null;
		private var mCoordinator:Coordinator = null;
		
		// configs
		private var mGridHeight:int = 16;
		private var mGridWidth:int = 32;
		private var mMapSpeed:Number = 32;
		
		public function MainScene()
		{
			with( this ) {
				percentWidth = 100; percentHeight = 100;
			}
			
			matsControl = new EditMatsControl(this);
			
			//selectBoard = new MatInputForm(selectControl);
			//this.addChild(selectBoard);
			//			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			//			this.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
			//			this.addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
			//			mBackgroundColor.addEventListener(MouseEvent.MOUSE_OUT, onBGMouseOut);
			
			var s:* = Data.getInstance().conf.mapSpeed;
			if( s && s>0 ) this.mMapSpeed = s;
			
			var w:* = Data.getInstance().conf.gridWidth;
			if( w && w>0 ) this.mGridWidth = w;
			
			var h:* = Data.getInstance().conf.gridHeight;
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
			//this.addElement( this.mMonsterMask );
			//this.mMonsterLayer.mask = this.mMonsterMask;
			
			//this.mMonsterLayer = new Group();
			//this.mAdaptiveLayer.addElement( this.mMonsterLayer );
			
			// scene
			this.mMonsterLayer.addEventListener( MouseEvent.CLICK, this.onMouseClick );
			this.addEventListener( MouseEvent.CLICK, this.onMouseClick );
			
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
			
			this.addEventListener( MouseEvent.MOUSE_WHEEL, onWheelMove );
			this.addEventListener( MouseEvent.MOUSE_MOVE, 
				function(e:MouseEvent):void
				{
					self.mMousePos.text = 
						"鼠标位置：("+int(self.mCoordinator.mouseX)+", "+
									int(-self.mCoordinator.mouseY+self.mProgressInPixel)+")";
					self.updateMouseTips();
				}
			);
			this.addEventListener( ResizeEvent.RESIZE, onResize );
			
			Runtime.getInstance().addEventListener( 
				Runtime.SELECT_DATA_CHANGE, this.onSelectChange
			);
		}
		
		public function reset( lid:String ):void
		{
			// clean up
			this.mMonsters = new Vector.<Component>();
			this.mMonsterLayer.removeChildren();

			// 
			var level:Object = Data.getInstance().getLevelDataById( lid );
			if( !level ) level = { data:[], endTime:0 };
			
			for each( var item:Object in level.data )
			{
				var one:Component = this.creator( item.type );			
				one.initFromData(item);
				this.insertMonster( one );
			}
		}
		
		// ------------------------------------------------------------
		// user configs
//		private function onChangeSpeed
		
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
					m2.y = min + (m2.y-min) * (1+e.delta*0.05);
			}else
				this.setProgress( this.mProgressInPixel + e.delta );
		}
		
		private function onMouseClick(e:MouseEvent):void
		{
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
						this.insertMonster( item );
					}
				} else {
					item = this.creator( type );
					item.x 	= this.mCoordinator.mouseX; 
					item.y	= this.mCoordinator.mouseY - this.mProgressInPixel; 
					this.insertMonster( item );
				}
			}
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
			this.mMapLength.text = "地图长度："+Utils.getTimeFormat(this.mFinishingLine);
		}
		private static var gMonsterCountor:int = 0;
		private function insertMonster( item:Component ):void
		{
			if( item.sid == "" || !item.sid ) 
				item.sid = new Date().time+String( gMonsterCountor++ );
			
			this.mMonsterLayer.addElement( item );
			this.mMonsters.push( item );
			this.onMonsterChange();
		}
		
		
		
		// 
		
		
//		
		
		private function onAddToStage(e:Event):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
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

		
		private function onBGMouseOut(e:MouseEvent):void
		{
			if(mSelectedTipsLayer)
			{
				this.removeChild(mSelectedTipsLayer);
				mSelectedTipsLayer = null;
			}
		}
		
		private function onSliderMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
		}
		
		public function snap(mats:Array):void
		{
//			for each(var m:Component in mats)
//			{
//				var pos:Point = new Point(m.x, m.y);
//				var pointOnGrid:Point = mCoordinator.globalToLocal(mapView.localToGlobal(pos));
//				var p:Point = mCoordinator.getGridPos(pointOnGrid.x, pointOnGrid.y);
//				m.x = p.x;
//				m.y = -mapView.y-p.y;
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
		//adjust views pos when the canvas size change
//		private function onResize(e:ResizeEvent = null):void
//		{
////			this.x = parContainer.width*0.5;
////			this.y = parContainer.height;
////			mBackgroundColor.graphics.clear();
////			mBackgroundColor.graphics.beginFill(0xAFEEEE);
////			mBackgroundColor.graphics.drawRect(-parContainer.width*0.5, -parContainer.height, parContainer.width, parContainer.height);
////			mBackgroundColor.graphics.endFill();
////			mVisibleMask.graphics.clear();
////			mVisibleMask.graphics.beginFill(0xffffff);
////			mVisibleMask.graphics.drawRect(-parContainer.width*0.5, -parContainer.height, parContainer.width, parContainer.height);
////			mVisibleMask.graphics.endFill();
////			mTimeline.x = -parContainer.width*0.5+50;
////			mTimeline.y = -parContainer.height+80;
//////			unitLabel.x = -170;
//////			unitLabel.y = -30;
//////			unitInput.x = -130;
//////			unitInput.y = -30;
//////			inputField.x = -parContainer.width*0.5+20;
//////			inputField.y = -parContainer.height+30;
//////			timeLabel.x = -parContainer.width*0.5+20;
//////			timeLabel.y = -parContainer.height+10;
////			mCoordinator.resize(parContainer.height);
////			mCoordinator.setCurrTime(currTime);
////			//selectBoard.x = -parContainer.width*0.5+30;
////			//selectBoard.y = -parContainer.height+600;
//		}
		
		
		private function updateSlider():void
		{
//			mTimeline.maximum = endTime;
//			mTimeline.value = currTime;
//			mTimeline.tickInterval = 10;
//			mTimeline.labels = ["0", String(endTime)];
		}
		
		//this called when endTime changed
		var timeLineInterval:int = mMapSpeed*5;
		private function updateMapSize():void
		{
//			var mapTileHeight = EditMapControl.getInstance().mMapHeight;
//			
//			var clipLow:Number = mapView.y;
//			var clipHigh:Number = mapView.y+parContainer.height;
//			var lowIndex:int = int(clipLow/mapTileHeight);
//			var highIndex:int = int(clipHigh/mapTileHeight);
//			
//			for(var i in mapPieces)
//				if(int(i) < lowIndex || int(i)>highIndex)
//				{
//					map.removeChild(mapPieces[i]);
//					mapFreePieces.push(mapPieces[i]);
//					delete mapPieces[i];
//				}
//			
//			for(var j:int = lowIndex; j <= highIndex; j++)
//				if(!mapPieces.hasOwnProperty(j))
//				{
//					var img:DisplayObject = mapFreePieces.length == 0 ? 
//											EditMapControl.getInstance().getAMap() : mapFreePieces.pop();
//					img.x = 0;
//					img.y = -j*mapTileHeight-mapTileHeight;
//					
//					map.addChild(img);
//					mapPieces[j] = img;
//				}
		}
		
		// ------------------------
		// facilities
		private function creator( type ):Component
		{
			if( type == AreaTriggerComponent.TRIGGER_TYPE )
				return new AreaTriggerComponent( this );
			else 
				return new EntityComponent( this, type, -1, 30 );
		}
		
	}
} 