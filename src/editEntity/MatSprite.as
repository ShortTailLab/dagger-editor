package editEntity
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	

	public class MatSprite extends EditBase
	{

		
		public var trimSize:Number;
		public var route:Array = null;
		
		
		private var isShowType:Boolean = false;
		private var skin:Sprite = null;
		private var selectFrame:Shape = null;
		private var typeText:TextField = null;
		private var typeSpr:Sprite = null;
		private var textWidth:int = 0;
		
		public function MatSprite(_type:String, size:int = -1, _textWidth:int = -1)
		{
			this.type = _type;
			this.trimSize = size;
			this.textWidth = _textWidth;
			init();
		}
		private function init():void
		{
			skin = new Sprite;
			this.addChild(skin);
			if(textWidth > 0)
			{
				typeSpr = new Sprite;
				typeText = new TextField;
				typeText.defaultTextFormat = new TextFormat(null, 20);
				typeText.autoSize = TextFieldAutoSize.CENTER;
				typeText.selectable = false;
				typeText.x = -typeText.textWidth*0.5;
				typeText.y = -typeText.textHeight*0.5;
				typeText.text = this.type;
				typeSpr.addChild(typeText);
				this.addChild(typeSpr);
				setTextWidth(textWidth);
			}
			
			if(Data.getInstance().enemySkinDic.hasOwnProperty(type))
			{
				var bmpd:BitmapData = Data.getInstance().enemySkinDic[type];
				var skinBmp:Bitmap = new Bitmap(bmpd);
				skinBmp.scaleX = skinBmp.scaleY = 0.5;
				skinBmp.x = -skinBmp.width*0.5;
				skinBmp.y = -skinBmp.height;
				skin.addChild(skinBmp);
			}
			else
			{
				var empty:TextField = new TextField();
				empty.defaultTextFormat = new TextFormat(null, 30, 0xff0000);
				empty.text = "?";
				empty.x = -empty.textWidth*0.5;
				empty.y = -empty.textHeight;
				empty.selectable = false;
				skin.addChild(empty);
			}
			
			if(trimSize > 0)
			{
				trim(trimSize);
			}
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
			if(trimSize > 0)
				trim(trimSize);
		}
		
		override public function select(value:Boolean):void
		{
			isSelected = value;
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
		
		override public function trim(size:Number):void
		{
			var scale:Number = Math.min(size/skin.width, size/skin.height);
			skin.scaleX = skin.scaleY = scale;
		}
		
		public function setTextWidth(value:int):void
		{
			var scale:Number = value/typeSpr.width;
			typeSpr.scaleX = typeSpr.scaleY = scale;
		}
		
		override public function initFromData(data:Object):void
		{
			this.x = data.x/2;
			this.y = -data.y/2;
			if(data.hasOwnProperty("triggerTime"))
				this.triggerTime = data.triggerTime;
		}
		
		override public function toExportData():Object
		{
			var obj:Object = new Object;
			obj.type = type;
			obj.x = x*2;
			obj.y = Number(-y*2);
			obj.id = id;
			if(this.triggerTime > 0)
				obj.triggerTime = this.triggerTime;
			return obj;
		}
	}
}