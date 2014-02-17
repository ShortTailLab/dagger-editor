package
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	import mx.containers.Canvas;
	import mx.controls.VSlider;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.events.SliderEvent;
	
	import spark.components.Button;
	import spark.components.TextInput;
	
	import editEntity.EditBase;
	import editEntity.MatFactory;
	
	
	public class EditView extends UIComponent
	{
		public var speed:Number = -1;//pixel per second
		
		private var bg:UIComponent = null;
		public var map:UIComponent = null;
		public var snapBtn:StateBtn = null;
		private var mapMask:Sprite = null;
		public var mapBg:UIComponent = null;
		private var timeLine:TimeLine = null;
		private var slider:VSlider = null;
		
		private var unitLabel:TextField = null;
		private var unitInput:TextInput = null;
		private var timeLabel:TextField = null;
		private var inputField:TextInput = null;
		private var submitBtn:Button = null;
		private var canvas:Canvas;
		private var scale:Number = 0.0;
		
		private var endTime:Number = -1;
		private var currTime:Number = -1;
		public var levelName:String = "";
		
		private var mapPieces:Dictionary;
		private var mapFreePieces:Array;
		
		public var matsControl:EditMatsControl;
		public var selectControl:SelectControl;
		private var selectBoard:SelectBoard;
		
		private var main:MapEditor = null;
		
		private var tipsContainer:Sprite = null;
		
		[Embed(source="map_snow1.png")]
		static public var BgImage:Class;
		
		public function EditView(_main:MapEditor, _container:Canvas)
		{
			this.main = _main;
			this.canvas = _container;
			this.canvas.addEventListener(ResizeEvent.RESIZE, onResize);
			speed = Data.getInstance().conf.speed;
			
			bg = new UIComponent;
			this.addChild(bg);
			
			map = new UIComponent;
			this.addChild(map);
			mapMask = new Sprite;
			this.addChild(mapMask);
			this.mask = mapMask;
			
			mapBg = new UIComponent;
			map.addChild(mapBg);
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
			map.addChild(timeLine);
			
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
			
			selectBoard = new SelectBoard(selectControl);
			this.addChild(selectBoard);
			
			setEndTime(canvas.height/speed);
			setCurrTime(0);
			
			onResize();
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
			this.addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
			this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			this.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			bg.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			
		}
		
		public function init(_levelName:String):void
		{
			if(levelName != "")
			{
				save();
			}
			this.levelName = _levelName;
			matsControl.clear();
			var level = Data.getInstance().getLevelData(levelName);
			matsControl.init(level.data);
			var end:int = level.endTime != 0? level.endTime : canvas.height/speed;
			setEndTime(end);
			setCurrTime(0);	
			
		}
		
		public function clear():void
		{
			this.levelName = "";
			matsControl.clear();
		}
		
		public function save():void
		{
			Data.getInstance().conf.timeLineUnit = int(unitInput.text);
			var data:Array = matsControl.getMatsData();
			Data.getInstance().updateLevelData(levelName, data, endTime);
		}
		
		private function onAddToStage(e:Event):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
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
		
		private function onEnterFrame(e:Event):void{
			map.y = currTime*speed;
			timeLine.y = -map.y;
			updateMapSize();
		}
		
		private function onWheel(e:MouseEvent):void{
			setCurrTime(currTime+e.delta);
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
				Formation.getInstance().add(selectControl.targets);
			}
			if(code == Keyboard.DELETE && selectControl.targets.length > 0)
			{
				var copy:Array = selectControl.targets.slice(0, selectControl.targets.length);
				for each(var m:EditBase in copy)
				{
					matsControl.remove(m.id);
				}
			}
		}
		private function onClick(e:MouseEvent):void
		{
			if(main.matsView.selected)
			{
				var type:String = main.matsView.selected.type;
				matsControl.add(type, e.localX, e.localY);
			}
		}
		private function onGridClick(e:TimeLineEvent):void
		{
			selectControl.unselect();
			if(main.fView.selected)
			{
				if(main.matsView.selected)
				{
					var posData:Array = Formation.getInstance().formations[main.fView.selected.fName];
					for each(var p in posData)
					{
						var type:String = main.matsView.selected.type;
						matsControl.add(type, e.data.x+p.x, -map.y-e.data.y+p.y);
					}
				}
			}
			else if(main.matsView.selected)
			{
				var type:String = main.matsView.selected.type;
				matsControl.add(type, e.data.x, -map.y-e.data.y);
			}
		}
		
		private function onMouseDown(e:MouseEvent):void{
			var localPoint:Point = map.globalToLocal(new Point(e.stageX, e.stageY));
			
		}
		private function onMouseMove(e:MouseEvent):void{
			var localPoint:Point = map.globalToLocal(new Point(e.stageX, e.stageY));
			
			updateMouseTips();
		}
		private function onMouseOut(e:MouseEvent):void
		{
			if(tipsContainer)
			{
				this.removeChild(tipsContainer);
				tipsContainer = null;
			}
		}
		private function onMouseUp(e:MouseEvent):void{
		}
		
		private function onSliderMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
		}
		
		public function snap(mats:Array):void
		{
			for each(var m:EditBase in mats)
			{
				var pos:Point = new Point(m.x, m.y);
				var pointOnGrid:Point = timeLine.globalToLocal(map.localToGlobal(pos));
				var p:Point = timeLine.getGridPos(pointOnGrid.x, pointOnGrid.y);
				m.x = p.x;
				m.y = -map.y-p.y;
			}
		}
		
		private function updateMouseTips():void
		{
			if(main.matsView.selected && !tipsContainer)
			{
				tipsContainer = new Sprite;
				tipsContainer.alpha = 0.5;
				var type:String = main.matsView.selected.type;
				if(main.fView.selected)
				{
					var posData:Array = Formation.getInstance().formations[main.fView.selected.fName];
					for each(var p in posData)
					{
						var mat:EditBase = MatFactory.createMat(type);
						mat.x = p.x;
						mat.y = p.y;
						tipsContainer.addChild(mat);
					}
				}
				else
				{
					var mat2:EditBase = MatFactory.createMat(type);
					tipsContainer.addChild(mat2);
				}
				this.addChild(tipsContainer);
			}
			else if(!main.matsView.selected && tipsContainer)
			{
				this.removeChild(tipsContainer);
				tipsContainer = null;
			}
			if(tipsContainer)
			{
				tipsContainer.x = this.mouseX-1;
				tipsContainer.y = this.mouseY-1;
			}
		}
		//adjust views pos when the canvas size change
		private function onResize(e:ResizeEvent = null):void
		{
			this.x = canvas.width*0.5;
			this.y = canvas.height;
			bg.graphics.clear();
			bg.graphics.beginFill(0xAFEEEE);
			bg.graphics.drawRect(-canvas.width*0.5, -canvas.height, canvas.width, canvas.height);
			bg.graphics.endFill();
			mapMask.graphics.clear();
			mapMask.graphics.beginFill(0xffffff);
			mapMask.graphics.drawRect(-canvas.width*0.5, -canvas.height, canvas.width, canvas.height);
			mapMask.graphics.endFill();
			slider.x = -canvas.width*0.5+50;
			slider.y = -canvas.height+80;
			unitLabel.x = -170;
			unitLabel.y = -30;
			unitInput.x = -130;
			unitInput.y = -30;
			inputField.x = -canvas.width*0.5+20;
			inputField.y = -canvas.height+30;
			timeLabel.x = -canvas.width*0.5+20;
			timeLabel.y = -canvas.height+10;
			timeLine.resize(canvas.height);
			timeLine.setCurrTime(currTime);
			selectBoard.x = -canvas.width*0.5+30;
			selectBoard.y = -canvas.height+600;
			snapBtn.x = -canvas.width*0.5+130;
			snapBtn.y = -canvas.height+80;
		}
		
		
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
		
		
		private function updateSlider():void
		{
			slider.maximum = endTime;
			slider.value = currTime;
			slider.tickInterval = 10;
			slider.labels = ["0", String(endTime)];
		}
		
		//this called when endTime changed
		var timeLineInterval:int = speed*5;
		var oneMapHigh:Number = 480;
		private function updateMapSize():void
		{
			var clipLow:Number = map.y;
			var clipHigh:Number = map.y+canvas.height;
			var lowIndex:int = int(clipLow/oneMapHigh);
			var highIndex:int = int(clipHigh/oneMapHigh);
			
			for(var i in mapPieces)
				if(int(i) < lowIndex || int(i)>highIndex)
				{
					mapBg.removeChild(mapPieces[i]);
					mapFreePieces.push(mapPieces[i]);
					delete mapPieces[i];
				}
			
			for(var j:int = lowIndex; j <= highIndex; j++)
				if(!mapPieces.hasOwnProperty(j))
				{
					var img:DisplayObject = mapFreePieces.length == 0 ? 
											EditMapControl.getInstance().getAMap() : mapFreePieces.pop();
					img.x = 0;
					img.y = -j*oneMapHigh-oneMapHigh;
					
					mapBg.addChild(img);
					mapPieces[j] = img;
				}
		}
		
		public function switchMap():void
		{
			for(var m in mapPieces)
			{
				mapBg.removeChild(mapPieces[m]);
			}
			mapPieces = new Dictionary;
			while(mapFreePieces.length > 0)
				mapFreePieces.pop();
			
			oneMapHigh = EditMapControl.getInstance().mapHeight;
		}
		
	}
} 