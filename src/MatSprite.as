package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import org.osmf.media.LoadableElementBase;
	

	public class MatSprite extends Sprite
	{
		public var type:String;
		public var triggerTime:int = -1;
		
		public var trimSize:Number;
		public var route:Array = null;
		public var isSelected:Boolean = false;
		
		private var isShowType:Boolean = false;
		private var skin:Sprite = null;
		private var selectFrame:Shape = null;
		
		public function MatSprite(_type:String, size:int = -1, showType:Boolean = false)
		{
			this.type = _type;
			this.isShowType = showType;
			this.trimSize = size;
			
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
			
			if(Data.getInstance().enemySkinDic.hasOwnProperty(type))
			{
				var bmpd:BitmapData = Data.getInstance().enemySkinDic[type];
				var skinBmp:Bitmap = new Bitmap(bmpd);
				skinBmp.scaleX = skinBmp.scaleY = 0.5;
				skinBmp.x = -skinBmp.width*0.5;
				skinBmp.y = -skinBmp.height;
				skin = new Sprite;
				this.addChild(skin);
				skin.addChild(skinBmp);
				if(trimSize > 0)
					trim(trimSize);
			}
			else
			{
				var path:String = Data.getInstance().enemyData[type].face+".png";
				var loader = new Loader;
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadSkin);
				loader.load(new URLRequest("Resource/"+path));
			}
			
		}
		
		public function enablePosChangeDispatch(value:Boolean):void
		{
			if(value)
			{
				posRecord = new Point(x, y);
				this.addEventListener(Event.ENTER_FRAME, onPosCheck);
			}
			else 
				this.removeEventListener(Event.ENTER_FRAME, onPosCheck);
		}
		
		private var posRecord:Point;
		private function onPosCheck(e:Event):void
		{
			if(posRecord.x != x || posRecord.y != y)
				this.dispatchEvent(new MsgEvent(MsgEvent.POS_CHANGE));
			posRecord.x = x;
			posRecord.y = y;
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
		
		public function select(value:Boolean):void
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
		
		public function trim(size:Number):void
		{
			var scale:Number = Math.min(size/skin.width, size/skin.height);
			skin.scaleX = skin.scaleY = scale;
		}
		
		public function initFromData(data:Object):void
		{
			this.x = data.x/2;
			this.y = -data.y*EditView.speed/100;
			if(data.hasOwnProperty("triggerTime"))
				this.triggerTime = data.triggerTime;
		}
		
		public function toExportData():Object
		{
			var obj:Object = new Object;
			obj.type = type;
			obj.x = x*2;
			obj.y = int(-y/EditView.speed*100);
			if(this.triggerTime > 0)
				obj.triggerTime = this.triggerTime;
			return obj;
		}
	}
}