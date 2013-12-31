package
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	

	public class MatSprite extends Sprite
	{
		public var type:String;
		public var triggerTime:int = -1;
		
		public var trimWidth:Number;
		public var route:Array = null;
		
		private var isShowType:Boolean = false;
		private var skin:Sprite = null;
		private var selectFrame:Shape = null;
		
		public function MatSprite(_type:String,  showType:Boolean = false)
		{
			this.type = _type;
			this.isShowType = showType;
			
			if(isShowType)
			{
				var typeText:TextField = new TextField;
				typeText.defaultTextFormat = new TextFormat(null, 20);
				typeText.autoSize = TextFieldAutoSize.CENTER;
				typeText.selectable = false;
				typeText.width = width;
				typeText.height = 20;
				typeText.x = -typeText.textWidth*0.5;
				typeText.y = -typeText.textHeight*0.5;
				typeText.text = this.type;
				this.addChild(typeText);
			}
			
			var path:String = Data.getInstance().enemyData[_type].face+".png";
			var loader = new Loader;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadSkin);
			loader.load(new URLRequest("Resource/"+path));
		}
		
		private function onLoadSkin(e:Event):void
		{
			var skinBmp:Bitmap = Bitmap((e.target as LoaderInfo).loader.content);
			skinBmp.scaleX = skinBmp.scaleY = 0.5;
			skinBmp.x = -skinBmp.width*0.5;
			skinBmp.y = -skinBmp.height;
			skin = new Sprite;
			this.addChild(skin);
			skin.addChild(skinBmp);
			if(trimWidth > 0)
				trim(trimWidth);
		}
		
		public function select(value:Boolean):void
		{
			if(value && !selectFrame)
			{
				selectFrame = new Shape;
				selectFrame.graphics.lineStyle(1, 0xff0000);
				selectFrame.graphics.drawRect(-skin.width*0.5, -skin.height, skin.width, skin.height);
				this.addChild(selectFrame);
			}
			else if(!value && selectFrame)
			{
				this.removeChild(selectFrame);
				selectFrame = null;
			}
		}
		
		public function trim(w:Number, h:Number = -1):void
		{
			var scale:Number = w/skin.width;
			if(skin.height*scale > h)
				scale = h/skin.height;
			skin.scaleX = skin.scaleY = scale;
			
		}
	}
}