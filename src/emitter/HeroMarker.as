package emitter
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	
	import mx.controls.Alert;
	
	public class HeroMarker extends Sprite
	{
		[Embed(source="assets/hero_marker.png")] 
		public static const ICON_EMITTER:Class;
		
		private var mImage:Bitmap;
		private var mData:Object;
		private var mPanel:EmitterPanel;
		
		public function HeroMarker() {
			this.buttonMode = true;
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		public function setData(data:Object, panel:EmitterPanel):void {
			mData = data;
			mPanel = panel;
			
			updateImage();
			updatePosition();
		}
		
		public function reset():void {	
			this.updatePosition();
		}
		
		public function setSelected(bool:Boolean):void {
			if (bool) {
				var filter:GlowFilter = new GlowFilter();
				filter.color = 0xFFFF00;
				filter.strength = 10;
				this.filters = [filter];
			}
			else {
				this.filters = [];
			}
		}
		
		public function updateImage():void {
			if (mImage) {
				removeChild(mImage);
				mImage = null;
			}
			
			mImage = new ICON_EMITTER();
			mImage.x -= mImage.width*0.5;
			mImage.y -= mImage.height*0.5;
			addChild(mImage);
		}
		
		private static var ERROR_IMAGE:Object = {};
		private function onLoadError(event:IOErrorEvent):void {
			Alert.show("英雄资源未找到，请确认资源", "图片加载错误", Alert.OK);
		}
		
		public function get posX():Number {
			return this.x*2;
		}
		
		public function get posY():Number {
			return -this.y*2;
		}
		
		public function updatePosition():void {
			this.x = mData.x/2;
			this.y = -mData.y/2;
			this.rotation = mData.rotation;
		}
		
		private function onImageLoad(event:Event):void  {
			mImage = event.currentTarget.loader.content;
			mImage.x = -mImage.width/2;
			mImage.y = -mImage.height/2;
			addChild(mImage);
		}
		
		private function onAdded(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		}
		
		private function onMouseDown(event:MouseEvent):void {
			var Width:int = 360;
			var Height:int = 640;
			
			this.startDrag(false, new Rectangle(-Width*0.5, -Height*0.5, Width, Height));
			this.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseUp(event:MouseEvent):void {
			this.stopDrag();
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseMove(event:MouseEvent):void {
			mData.x = this.x*2;
			mData.y = -this.y*2;
		}
		
		public function destroy():void {
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.parent.removeChild(this);
		}
	}
}