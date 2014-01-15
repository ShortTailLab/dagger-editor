package
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.containers.Canvas;
	import mx.controls.Text;
	import mx.controls.VSlider;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	import mx.events.SliderEvent;
	
	import spark.components.Button;
	import spark.components.TextInput;
	
	
	public class EditView extends UIComponent
	{
		static public var speed:Number = 32;//pixel per second
		
		private var map:UIComponent = null;
		private var mapMask:Sprite = null;
		public var mapBg:UIComponent = null;
		private var timeLine:TimeLine = null;
		private var slider:VSlider = null;
		private var snapBtn:StateBtn = null;
		private var unitLabel:TextField = null;
		private var unitInput:TextInput = null;
		private var inputField:TextInput = null;
		private var submitBtn:Button = null;
		private var canvas:Canvas;
		private var scale:Number = 0.0;
		
		private var endTime:Number = -1;
		private var currTime:Number = -1;
		private var levelName:String = "";
		
		private var displayMats:Array;
		
		private var mapPieces:Dictionary;
		private var mapFreePieces:Array;
		
		private var selectControl:SelectControl;
		private var selectRect:Rectangle;
		private var selectRectShape:Shape;
		private var selectBoard:SelectBoard;
		
		private var main:MapEditor = null;
		
		[Embed(source="background.jpg")]
		static public var BgImage:Class;
		
		public function EditView(_main:MapEditor, _container:Canvas)
		{
			this.main = _main;
			this.canvas = _container;
			this.canvas.addEventListener(ResizeEvent.RESIZE, onResize);
			
			displayMats = new Array;
			
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
			unitLabel.text = "单位：";
			this.addChild(unitLabel);
			
			unitInput = new TextInput;
			unitInput.width = 30;
			unitInput.height = 20;
			unitInput.restrict = "0123456789";
			unitInput.text = Data.getInstance().conf.timeLineUnit;
			this.addChild(unitInput);
			
			timeLine = new TimeLine(speed, 5, 9);
			timeLine.x = 0;
			timeLine.addEventListener("gridClick", onGridClick);
			map.addChild(timeLine);
			
			inputField = new TextInput;
			inputField.width = 80;
			inputField.height = 30;
			inputField.restrict = "0123456789";
			this.addChild(inputField);
			
			submitBtn = new Button();
			submitBtn.label = "确认";
			submitBtn.width = 50;
			submitBtn.height = 30;
			submitBtn.addEventListener(MouseEvent.CLICK, onSubmit);
			this.addChild(submitBtn);
			
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
			
			selectControl = new SelectControl(this);
			selectRect = new Rectangle(0, 0, 0, 0);
			selectRectShape = null;
			
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
		}
		
		public function init(_levelName:String):void
		{
			if(levelName != "")
				save();
			
			clear();
			
			this.levelName = _levelName;
			var level = Data.getInstance().getLevelData(levelName);
			for each(var item:Object in level.data)
			{
				var mat:MatSprite = new MatSprite(item.type);
				mat.initFromData(item);
				display(mat, mat.x, mat.y);
			}
			var end:int = level.endTime != 0? level.endTime : canvas.height/speed;
			setEndTime(end);
			setCurrTime(0);
		}
		
		public function clear():void
		{
			for each(var m:MatSprite in displayMats)
				map.removeChild(m);
			displayMats.splice(0, displayMats.length);
		}
		
		public function save():void
		{
			Data.getInstance().conf.timeLineUnit = int(unitInput.text);
			
			var data:Array = new Array;
			for each(var m:MatSprite in displayMats)
				data.push(m.toExportData());
			Data.getInstance().updateLevelData(levelName, data, endTime);
		}
		private function onAddToStage(e:Event):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function onSubmit(e:MouseEvent):void
		{
			setCurrTime(int(inputField.text));
		}
		
		private function onsliderChange(e:SliderEvent):void
		{
			setCurrTime(e.value);
		}
		
		private function onEnterFrame(e:Event):void{
			map.y = currTime*speed;
			timeLine.y = -map.y;
			updateMapSize();
			
			if(draggingMats && draggingMats.length > 0)
			{
				var dx:Number = map.mouseX - currDragPoint.x;
				var dy:Number = map.mouseY - currDragPoint.y;
				if(dx != 0 || dy != 0)
				{
					for each(var m:MatSprite in draggingMats)
					{
						m.x += dx;
						m.y += dy;
					}
					currDragPoint.x = map.mouseX;
					currDragPoint.y = map.mouseY;
				}
			}
		}
		
		private function onWheel(e:MouseEvent):void{
			setCurrTime(currTime+e.delta);
		}
		private function onKeyDown(e:KeyboardEvent):void
		{
			var code:uint = e.keyCode;
			if(code == Keyboard.ENTER)
				onSubmit(null);
			if(code == Keyboard.C && e.ctrlKey && selectControl.targets.length > 0)
			{
				this.copySelect();
			}
			if(code == Keyboard.F && e.ctrlKey && selectControl.targets.length > 0)
			{
				Formation.getInstance().add(selectControl.targets);
			}
			if(code == Keyboard.DELETE && selectControl.targets.length > 0)
			{
				var copy:Array = selectControl.targets.slice(0, selectControl.targets.length);
				for each(var m:MatSprite in copy)
				{
					removeMat(m);
				}
			}
		}
		private function onClick(e:MouseEvent):void
		{
			if(main.matsView.selected)
			{
				var type:String = main.matsView.selected.type;
				var mat:MatSprite = new MatSprite(type);
				
				display(mat, e.localX, e.localY);
			}
		}
		private function onGridClick(e:TimeLineEvent):void
		{
			selectControl.unselect();
			if(!selectRectShape)
			{
				if(main.fView.selected)
				{
					if(main.matsView.selected)
					{
						var posData:Array = Formation.getInstance().formations[main.fView.selected.fName];
						for each(var p in posData)
						{
							var type:String = main.matsView.selected.type;
							var mat:MatSprite = new MatSprite(type);
							display(mat, e.data.x+p.x, -map.y-e.data.y+p.y);
						}
					}
				}
				else if(main.matsView.selected)
				{
					var type:String = main.matsView.selected.type;
					var mat:MatSprite = new MatSprite(type);
					display(mat, e.data.x, -map.y-e.data.y);
				}
			}
			
		}
		
		private var isSelecting:Boolean = false;
		private function onMouseDown(e:MouseEvent):void{
			var localPoint:Point = map.globalToLocal(new Point(e.stageX, e.stageY));
			selectRect.x = localPoint.x;
			selectRect.y = localPoint.y;
			isSelecting = true;
		}
		private function onMouseMove(e:MouseEvent):void{
			if(isSelecting)
			{
				var localPoint:Point = map.globalToLocal(new Point(e.stageX, e.stageY));
				if(!selectRectShape)
				{
					selectRectShape = new Shape;
					map.addChild(selectRectShape);
				}
				selectRect.width = localPoint.x - selectRect.x;
				selectRect.height = localPoint.y - selectRect.y;
				updateSelectRect();
			}
		}
		private function onMouseUp(e:MouseEvent):void{
			isSelecting = false;
			if(selectRectShape)
			{
				selectControl.selectMul(getSelectMats(selectRectShape));
				map.removeChild(selectRectShape);
				selectRectShape = null;
			}
		}
		private function onSliderMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
		}
		private function getSelectMats(frame:DisplayObject):Array
		{
			var result:Array = new Array;
			for each(var m:MatSprite in displayMats)
				if(m.hitTestObject(frame))
					result.push(m);
			return result;
		}
		
		private var draggingMats:Array = null;
		private var currDragPoint:Point;
		private function onMatMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
			currDragPoint = new Point(map.mouseX, map.mouseY);
			var _draggingMat:MatSprite = e.currentTarget as MatSprite;
			if(_draggingMat.isSelected)
				draggingMats = selectControl.targets;
			else
				draggingMats = new Array(e.currentTarget as MatSprite);
			
			this.stage.addEventListener(MouseEvent.MOUSE_UP, onMatMouseUp);
		}
		
		private function onMatMouseUp(e:MouseEvent):void {
			if(snapBtn.isOn)
				snap(draggingMats);
			
			draggingMats = null;
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, onMatMouseUp);
		}
		private function onMatMiddleClick(e:MouseEvent):void {
			e.stopPropagation();
			removeMat(e.currentTarget as MatSprite);
		}
		private function onMatClick(e:MouseEvent):void
		{
			e.stopPropagation();

			var target:MatSprite = e.currentTarget as MatSprite;
			selectControl.select(target);
		}
		
		private function snap(mats:Array):void
		{
			for each(var m:MatSprite in mats)
			{
				var pos:Point = new Point(m.x, m.y);
				var pointOnGrid:Point = timeLine.globalToLocal(map.localToGlobal(pos));
				var p:Point = timeLine.getGridPos(pointOnGrid.x, pointOnGrid.y);
				m.x = p.x;
				m.y = -map.y-p.y;
			}
		}
		private function display(mat:MatSprite, px:Number, py:Number):void
		{
			mat.addEventListener(MouseEvent.MOUSE_DOWN, onMatMouseDown);
			mat.addEventListener(MouseEvent.MIDDLE_CLICK, onMatMiddleClick);
			mat.addEventListener(MouseEvent.CLICK, onMatClick);
			mat.x = px;
			mat.y = py;
			map.addChild(mat);
			displayMats.push(mat);
		}
		public function copySelect():void
		{
			var newMats:Array = new Array;
			for each(var m:MatSprite in selectControl.targets)
			{
				var newM:MatSprite = new MatSprite(m.type);
				display(newM, m.x+30, m.y+30);
				newMats.push(newM);
			}
			selectControl.selectMul(newMats);
		}
		
		public function removeMat(mat:MatSprite):void
		{
			if(!mat)
				return;
			mat.removeEventListener(MouseEvent.MOUSE_DOWN, onMatMouseDown);
			mat.removeEventListener(MouseEvent.MIDDLE_CLICK, onMatMiddleClick);
			map.removeChild(mat);
			for(var i:int = 0; i < displayMats.length; i++)
				if(displayMats[i] == mat)
				{
					displayMats.splice(i, 1);
					break;
				}
		}
		
		
		//adjust views pos when the canvas size change
		private function onResize(e:ResizeEvent = null):void
		{
			this.x = canvas.width*0.5;
			this.y = canvas.height;
			map.graphics.clear();
			map.graphics.beginFill(0xffffff);
			map.graphics.drawRect(-canvas.width*0.5, -canvas.height, canvas.width, canvas.height);
			map.graphics.endFill();
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
			inputField.x = -canvas.width*0.5+30;
			inputField.y = -canvas.height+30;
			submitBtn.x = -canvas.width*0.5+120;
			submitBtn.y = -canvas.height+30;
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
		
		private function updateSelectRect():void
		{
			selectRectShape.graphics.clear();
			if(isSelecting && selectRect)
			{
				selectRectShape.x = selectRect.x;
				selectRectShape.y = selectRect.y;
				selectRectShape.graphics.lineStyle(1);
				selectRectShape.graphics.drawRect(0, 0, selectRect.width, selectRect.height);
			}
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