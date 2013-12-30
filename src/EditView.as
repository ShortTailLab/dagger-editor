package
{
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	import mx.containers.Canvas;
	import mx.controls.VSlider;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	import mx.events.SliderEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
	import spark.components.TextInput;
	
	
	public class EditView extends UIComponent
	{
		private var map:Sprite = null;
		private var mapBg:Sprite = null;
		private var timeLine:TimeLine = null;
		private var slider:VSlider = null;
		private var inputField:TextInput = null;
		private var submitBtn:Button = null;
		private var canvas:Canvas;
		private var scale:Number = 0.0;
		
		private var speed:Number = 20;//pixel per second
		private var endTime:Number = -1;
		private var currTime:Number = -1;
		private var levelName:String = "";
		
		private var displayMats:Array;
		
		private var mapPieces:Dictionary;
		
		private var selectRect:Rectangle;
		private var selectRectShape:Shape;
		
		[Embed(source="background.jpg")]
		static public var BgImage:Class;
		
		public function EditView(_container:Canvas)
		{
			this.canvas = _container;
			this.canvas.addEventListener(ResizeEvent.RESIZE, onResize);
			
			displayMats = new Array;
			map = new Sprite;
			map.x = -60;
			this.addChild(map);
			
			mapBg = new Sprite;
			map.addChild(mapBg);
			mapPieces = new Dictionary;
			
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
			this.addChild(slider);
			
			selectRect = new Rectangle(0, 0, 0, 0);
			selectRectShape = null;
			
			setEndTime(canvas.height/speed);
			setCurrTime(0);
			
			onResize();
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
			this.addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
			map.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			map.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			map.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		public function init(_levelName:String):void
		{
			if(levelName != "")
				save();
			
			for each(var m:MatSprite in displayMats)
				map.removeChild(m);
			displayMats.splice(0, displayMats.length);
			
			this.levelName = _levelName;
			var level = Data.getInstance().getLevelData(levelName);
			for each(var item in level.data)
			{
				var mat:MatSprite = new MatSprite(item.type);
				display(mat, item.x/2, -item.y*speed/100);
			}
			var end:int = level.endTime != 0? level.endTime : canvas.height/speed;
			setEndTime(end);
			setCurrTime(0);
		}
		
		public function save():void
		{
			var data:Array = new Array;
			for each(var m:MatSprite in displayMats)
			{
				var obj:Object = new Object;
				obj.type = m.type;
				obj.x = m.x*2;
				obj.y = -m.y/speed*100;
				data.push(obj);
			}
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
		}
		
		private function onWheel(e:MouseEvent):void{
			setCurrTime(currTime+e.delta);
		}
		private function onKeyDown(e:KeyboardEvent):void
		{
			if(e.keyCode == Keyboard.ENTER)
				onSubmit(null);
		}
		private function onClick(e:MouseEvent):void
		{
			if(MatsView.getInstance().selected)
			{
				var type:String = MatsView.getInstance().selected.type;
				var mat:MatSprite = new MatSprite(type);
				
				display(mat, e.localX, e.localY);
			}
		}
		private function onGridClick(e:TimeLineEvent):void
		{
			if(MatsView.getInstance().selected && !selectRectShape)
			{
				var type:String = MatsView.getInstance().selected.type;
				var mat:MatSprite = new MatSprite(type);
				display(mat, e.data.x, -map.y-e.data.y);
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
				map.removeChild(selectRectShape);
				selectRectShape = null;
				
			}
		}
		
		
		private function onMatMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
			_draggingMat = e.currentTarget as MatSprite;
			_draggingMat.startDrag();
			this.stage.addEventListener(MouseEvent.MOUSE_UP, onMatMouseUp);
		}
		private var _draggingMat:MatSprite;
		private function onMatMouseUp(e:MouseEvent):void {
			_draggingMat.stopDrag();
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, onMatMouseUp);
		}
		private function onMatMiddleClick(e:MouseEvent):void {
			e.stopPropagation();
			removeMat(e.currentTarget as MatSprite);
		}
		private function display(mat:MatSprite, px:Number, py:Number):void
		{

			mat.addEventListener(MouseEvent.MOUSE_DOWN, onMatMouseDown);
			mat.addEventListener(MouseEvent.MIDDLE_CLICK, onMatMiddleClick);
			mat.x = px;
			mat.y = py;
			map.addChild(mat);
			displayMats.push(mat);
		}

		
		private function removeMat(mat:MatSprite):void
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
		private function onResize(e:ResizeEvent = null):void{
			this.x = canvas.width*0.5;
			this.y = canvas.height;
			slider.x = -canvas.width*0.5+50;
			slider.y = -canvas.height+80;
			inputField.x = -canvas.width*0.5+30;
			inputField.y = -canvas.height+30;
			submitBtn.x = -canvas.width*0.5+120;
			submitBtn.y = -canvas.height+30;
			timeLine.resize(canvas.height);
			timeLine.setCurrTime(currTime);
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
		var oneMapHigh:int = 480;
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
					delete mapPieces[i];
				}
			
			for(var j:int = lowIndex; j <= highIndex; j++)
				if(!mapPieces.hasOwnProperty(j))
				{
					var img:Bitmap = new BgImage as Bitmap;
					img.scaleX = img.scaleY = 0.5;
					img.x = 0;
					img.y = -j*oneMapHigh-img.height;
					//img.visible = false;
					mapBg.addChild(img);
					mapPieces[j] = img;
				}
			
		}

		
	}
}