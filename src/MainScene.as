/*
this view contains the map,the time scroller, the inputform.
*/
package 
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.containers.Canvas;
	import mx.controls.VSlider;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.events.SliderEvent;
	
	import spark.components.Button;
	import spark.components.TextInput;
	
	import mapEdit.Component;
	import mapEdit.EditMapControl;
	import mapEdit.EditMatsControl;
	import mapEdit.MatFactory;
	import mapEdit.MatInputForm;
	import mapEdit.SelectControl;
	import mapEdit.TimeLine;
	import mapEdit.TimeLineEvent;
	
	import tools.StateBtn;
	
	
	public class MainScene extends UIComponent
	{
		public var speed:Number = -1;//pixel per second
		//mapView contains the map,the grid above and all mats.
		public var mapView:UIComponent = null;
		public var map:UIComponent = null;
		
		//matsControl handle all the add and remove actions of mat.
		public var matsControl:EditMatsControl;
		public var selectControl:SelectControl;
		
		private var editViewMask:Sprite = null;
		private var editViewBg:UIComponent = null;
		
		public var snapBtn:StateBtn = null;
		
		private var timeLine:TimeLine = null;
		private var slider:VSlider = null;
		
		private var unitLabel:TextField = null;
		private var unitInput:TextInput = null;
		private var timeLabel:TextField = null;
		private var inputField:TextInput = null;
		private var submitBtn:Button = null;
		private var parContainer:Canvas;
		private var scale:Number = 0.0;
		
		private var endTime:Number = -1;
		private var currTime:Number = -1;
		private var level_id:String = "";
		//used to the map recycle.
		private var mapPieces:Dictionary;
		private var mapFreePieces:Array;
		
		private var selectBoard:MatInputForm;
		//跟随鼠标的一些提示
		private var mSelectedTipsLayer:Sprite = null;
		
		private var tipsTimer:Timer = null;
		
		[Embed(source="map_snow1.png")]
		static public var BgImage:Class;
		
		public function MainScene(_container:Canvas)
		{
			//all the ui position will be recalculated in onResize()
			
			this.parContainer = _container;
			this.parContainer.addEventListener(ResizeEvent.RESIZE, onResize);
			if( Data.getInstance().conf.speed == 0 )
				speed = 32;
			else
				speed = Data.getInstance().conf.speed ;
			
			editViewBg = new UIComponent;
			this.addChild(editViewBg);
			
			mapView = new UIComponent;
			this.addChild(mapView);
			editViewMask = new Sprite;
			this.addChild(editViewMask);
			this.mask = editViewMask;
			
			map = new UIComponent;
			mapView.addChild(map);
			mapPieces = new Dictionary;
			mapFreePieces = new Array;

			unitLabel = new TextField;
			unitLabel.defaultTextFormat = new TextFormat(null, 14);
			unitLabel.text = "速度：";
			this.addChild(unitLabel);
			
			unitInput = new TextInput;
			unitInput.width = 30;
			unitInput.height = 20;
			unitInput.restrict = "0123456789";
			unitInput.text = Data.getInstance().conf.speed;
			unitInput.addEventListener(FlexEvent.ENTER, onSpeedSubmit);
			this.addChild(unitInput);
			
			timeLine = new TimeLine(speed, 5, 9);
			timeLine.x = 0;
			timeLine.addEventListener("gridClick", onGridClick);
			mapView.addChild(timeLine);
			
			timeLabel = Utils.getLabel("当前时间：", 0, 0, 14);
			this.addChild(timeLabel);
			inputField = new TextInput;
			inputField.width = 80;
			inputField.height = 30;
			inputField.restrict = "0123456789";
			inputField.addEventListener(FlexEvent.ENTER, onCurrTimeSubmit);
			this.addChild(inputField);
			
			slider = new VSlider;
			slider.showDataTip = true;
			slider.minimum = 0;
			slider.snapInterval = 1;
			slider.height = 500;
			slider.liveDragging = true;
			slider.addEventListener(SliderEvent.CHANGE, onsliderChange);
			slider.addEventListener(MouseEvent.MOUSE_DOWN, onSliderMouseDown);
			this.addChild(slider);
			snapBtn = new StateBtn("黏贴");
			this.addChild(snapBtn);
			
			matsControl = new EditMatsControl(this);
			selectControl = new SelectControl(this);
			
			selectBoard = new MatInputForm(selectControl);
			this.addChild(selectBoard);
			
			setEndTime(parContainer.height/speed);
			setCurrTime(0);
			
			onResize();
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
			this.addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
			editViewBg.addEventListener(MouseEvent.MOUSE_OUT, onBGMouseOut);
			
			var self:MainScene = this;
			this.tipsTimer = new Timer(0.03, 1);
			this.tipsTimer.addEventListener(TimerEvent.TIMER, 
				function():void
				{
					self.updateMouseTips();
					self.tipsTimer.reset();
					self.tipsTimer.start();
				}
			);
			this.tipsTimer.start();
			
			Runtime.getInstance().addEventListener( 
				Runtime.SELECT_DATA_CHANGE, this.onSelectChange
			);
		}
		
		public function init(lid:String):void
		{
			if(this.level_id != "")
			{
				save();
			}
			this.level_id = lid;
			matsControl.clear();
			
			var level = Data.getInstance().getLevelDataById(lid);
			if( !level ) level = { data : [], endTime : 0 };
			
			matsControl.init(level.data);
			var end:int = level.endTime != 0? level.endTime : parContainer.height/speed;
			setEndTime(end);
			setCurrTime(0);	
		}
		
		public function save():void
		{
			Data.getInstance().conf.speed = int(unitInput.text);
			var data:Array = matsControl.getMatsData();
			Data.getInstance().updateLevelDataById(this.level_id, {
				data:data, endTime:endTime
			});
		}
		
		//the map's current time.
		public function setCurrTime(value:Number):void
		{
			if(value < 0)
			{
				return;
			}
			currTime = value;
			if(currTime > endTime)
				setEndTime(currTime);
			updateSlider();
			timeLine.setCurrTime(currTime);
		}
		
		public function setEndTime(value:Number):void
		{
			if(value < 0)
			{
				return;
			}
			if(value != endTime)
			{
				endTime = value;
			}
		}
		
		private function onAddToStage(e:Event):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		private function onKeyDown(e:KeyboardEvent):void
		{
			var code:uint = e.keyCode;
			if(code == Keyboard.C && e.ctrlKey && selectControl.targets.length > 0)
			{
				selectControl.copySelect();
			}
			if(code == Keyboard.F && e.ctrlKey && selectControl.targets.length > 0)
			{
				selectControl.setSelectMatToFormation();
			}
			if(code == Keyboard.DELETE && selectControl.targets.length > 0)
			{
				var copy:Array = selectControl.targets.slice(0, selectControl.targets.length);
				for each(var m:Component in copy)
				{
					matsControl.remove(m.sid);
				}
			}
		}
		private function onCurrTimeSubmit(e:FlexEvent):void
		{
			setCurrTime(int(inputField.text));
		}
		private function onSpeedSubmit(e:FlexEvent):void
		{
			var speed:int = int(unitInput.text);
			Data.getInstance().conf.speed = speed;
			timeLine.setSpeed(speed);
			timeLine.setCurrTime(currTime);
		}
		
		private function onsliderChange(e:SliderEvent):void
		{
			setCurrTime(e.value);
		}
		
		private function onEnterFrame(e:Event):void
		{
			mapView.y = currTime*speed;
			timeLine.y = -mapView.y;
			updateMapSize();
		}
		
		private function onWheel(e:MouseEvent):void{
			if(e.ctrlKey)
			{
				var minY:Number = matsControl.mats[0].y;
				matsControl.mats.forEach(function(m){minY = Math.max(m.y, minY);}, this);
				
				for each(var m in matsControl.mats)
				{
					m.y = minY+(m.y-minY)*(1+e.delta*0.05);
				}
			}
			else
				setCurrTime(currTime+e.delta);
		}

		private function onGridClick(e:TimeLineEvent):void
		{
			selectControl.unselect();
			
			var type:String = Runtime.getInstance().selectedComponentType;
			var fid:String = Runtime.getInstance().selectedFormationType;

			if( type )
			{
				if( fid )
				{
					var posData:Object = Data.getInstance().getFormationById( fid );
					for each( var p:Object in posData )
						matsControl.add(type, e.data.x+p.x, -mapView.y-e.data.y+p.y);
				}else
					matsControl.add(type, e.data.x, -mapView.y-e.data.y);
			}
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
			for each(var m:Component in mats)
			{
				var pos:Point = new Point(m.x, m.y);
				var pointOnGrid:Point = timeLine.globalToLocal(mapView.localToGlobal(pos));
				var p:Point = timeLine.getGridPos(pointOnGrid.x, pointOnGrid.y);
				m.x = p.x;
				m.y = -mapView.y-p.y;
			}
		}
		
		private var mSelectType:String 		= null;
		private var mSelectFormation:String = null;
		private function onSelectChange(e:Event):void 
		{
			if( (this.mSelectType != Runtime.getInstance().selectedComponentType ||
				 this.mSelectFormation != Runtime.getInstance().selectedFormationType) 
				&& this.mSelectedTipsLayer )
			{
				this.removeChild( this.mSelectedTipsLayer );
				this.mSelectedTipsLayer = null;
			}
			
			this.mSelectedTipsLayer = new Sprite;
			this.addChild( this.mSelectedTipsLayer );
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
						mSelectedTipsLayer.addChild(mat);
					}
				}
				else 
				{
					var mat2:Component = MatFactory.createMat(this.mSelectType);
					mSelectedTipsLayer.addChild(mat2);
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
		private function onResize(e:ResizeEvent = null):void
		{
			this.x = parContainer.width*0.5;
			this.y = parContainer.height;
			editViewBg.graphics.clear();
			editViewBg.graphics.beginFill(0xAFEEEE);
			editViewBg.graphics.drawRect(-parContainer.width*0.5, -parContainer.height, parContainer.width, parContainer.height);
			editViewBg.graphics.endFill();
			editViewMask.graphics.clear();
			editViewMask.graphics.beginFill(0xffffff);
			editViewMask.graphics.drawRect(-parContainer.width*0.5, -parContainer.height, parContainer.width, parContainer.height);
			editViewMask.graphics.endFill();
			slider.x = -parContainer.width*0.5+50;
			slider.y = -parContainer.height+80;
			unitLabel.x = -170;
			unitLabel.y = -30;
			unitInput.x = -130;
			unitInput.y = -30;
			inputField.x = -parContainer.width*0.5+20;
			inputField.y = -parContainer.height+30;
			timeLabel.x = -parContainer.width*0.5+20;
			timeLabel.y = -parContainer.height+10;
			timeLine.resize(parContainer.height);
			timeLine.setCurrTime(currTime);
			selectBoard.x = -parContainer.width*0.5+30;
			selectBoard.y = -parContainer.height+600;
			snapBtn.x = -parContainer.width*0.5+130;
			snapBtn.y = -parContainer.height+80;
		}
		
		
		private function updateSlider():void
		{
			slider.maximum = endTime;
			slider.value = currTime;
			slider.tickInterval = 10;
			slider.labels = ["0", String(endTime)];
		}
		
		//this called when endTime changed
		var timeLineInterval:int = speed*5;
		private function updateMapSize():void
		{
			var mapTileHeight = EditMapControl.getInstance().mMapHeight;
			
			var clipLow:Number = mapView.y;
			var clipHigh:Number = mapView.y+parContainer.height;
			var lowIndex:int = int(clipLow/mapTileHeight);
			var highIndex:int = int(clipHigh/mapTileHeight);
			
			for(var i in mapPieces)
				if(int(i) < lowIndex || int(i)>highIndex)
				{
					map.removeChild(mapPieces[i]);
					mapFreePieces.push(mapPieces[i]);
					delete mapPieces[i];
				}
			
			for(var j:int = lowIndex; j <= highIndex; j++)
				if(!mapPieces.hasOwnProperty(j))
				{
					var img:DisplayObject = mapFreePieces.length == 0 ? 
											EditMapControl.getInstance().getAMap() : mapFreePieces.pop();
					img.x = 0;
					img.y = -j*mapTileHeight-mapTileHeight;
					
					map.addChild(img);
					mapPieces[j] = img;
				}
		}
		
	}
} 