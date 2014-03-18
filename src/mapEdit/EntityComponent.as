package mapEdit
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.LoaderInfo;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	

	public class EntityComponent extends Component
	{
		public var trimSize:Number;
		public var route:Array = null;
		private var isShowType:Boolean = false;
		private var skin:Sprite = null;
		private var selectFrame:Shape = null;
		private var typeText:TextField = null;
		private var typeSpr:Sprite = null;
		private var textWidth:int = 0;
		
		public function EntityComponent(_editView:EditView = null, _type:String = "", size:int = -1, _textWidth:int = -1)
		{
			super(_editView, _type);
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

			var face:String = Data.getInstance().getEnemyProfileById(this.type).face;
			var data:BitmapData = Data.getInstance().getSkinById( face );
			if( data )
			{
				var bmpd:BitmapData = data;
				
				skinBmp = new Bitmap(bmpd);
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
		var skinBmp:Bitmap;
		private function onLoadSkin(e:Event):void
		{
			skinBmp = Bitmap((e.target as LoaderInfo).loader.content);
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
				showTrigger();
			}
			else if(!value && selectFrame)
			{
				if(triggerShadow)
				{
					this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
					this.removeChild(triggerShadow);
					triggerShadow = null;
				}
				this.removeChild(selectFrame);
				selectFrame = null;
				
			}
		}
		
		private var triggerShadow:Component = null;
		public function showTrigger():void
		{
			if(this.triggerTime > 0 && !triggerShadow)
			{
				triggerShadow = MatFactory.createMat(this.type);
				triggerShadow.alpha = 0.5;
				triggerShadow.x = 0;
				triggerShadow.y = 0;
				this.addChild(triggerShadow);
				this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			else if(this.triggerTime == 0 && triggerShadow)
			{
				this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				this.removeChild(triggerShadow);
				triggerShadow = null;
			}
		}
		
		private function onEnterFrame(e:Event):void
		{
			if(this.triggerTime>0 && triggerShadow)
			{
				triggerShadow.y = -this.triggerTime/2-this.y;
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
			this.sid = data.id;
			this.x = data.x/2;
			this.y = -data.y/2;
			if( data.hasOwnProperty("triggerTime") ) this.triggerTime = data.triggerTime;
		}
		
		override public function toExportData():Object
		{
			var obj:Object = new Object;
			obj.id = this.sid;
			obj.type = this.type;
			obj.x = this.x*2;
			obj.y = Number(-this.y*2);
			
			if( this.triggerTime > 0 ) obj.triggerTime = this.triggerTime;
			
			return obj;
		}
	}
}