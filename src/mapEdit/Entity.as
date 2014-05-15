package mapEdit
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class Entity extends Component
	{
		private var mProfileScalor:Number = 1.0;
		private var mSkin:Sprite = null;
		private var mEnableTextTips:Boolean = false;
		private var mTextTips:TextField = null;
		
		private var mUnderSelection:Boolean = false;
		private var mSelectedFrame:Shape = null;
		
		private var mShadowTips:Entity = null;
		
		public function Entity(type:String, enableText:Boolean = false)
		{
			this.mEnableTextTips = enableText;
			this.reset( type );
		}
		
		// --- > related data 
		private var mTriggeredTime:Number = -1;
		private var mSectionDelay:Number = 1;
		//private var x, y 
		
		public function reset( type:String ):void 
		{
			// clean up
			this.removeChildren();
			
			this.mClassId = type;
			var profile:* = Data.getInstance().getEnemyProfileById( 
				Runtime.getInstance().currentLevelID, type 
			);
			
			// --- > skin
			this.mSkin = new Sprite;
			var data:Object = Data.getInstance().getSkinById( profile.face );
			if( data != "icu" && data ) {
				var bmpd:BitmapData = data as BitmapData;
				var skinBmp:Bitmap = new Bitmap(bmpd);
				with( skinBmp ) {
					x = -width*0.5; y = -height;
				}
				this.mSkin.addChild(skinBmp);
			} else {
				var empty:TextField = new TextField();
				with( empty ) {
					defaultTextFormat = new TextFormat(null, 30, 0xff0000);
					text = "?"; 				
					x = -textWidth*0.5; y = -textHeight;
				}
				this.mSkin.addChild( empty );
			}
			this.addChild( this.mSkin );
			
			if( this.mEnableTextTips && !this.mTextTips )
			{
				this.mTextTips = new TextField;
				with( this.mTextTips ) {
					defaultTextFormat = new TextFormat(null, 16);
					selectable = false;
					text = profile.monster_name;
					x = -width/2.3;
				}
				this.mTextTips.autoSize = flash.text.TextFieldAutoSize.CENTER;
				this.addChild( this.mTextTips );
			}
		}
	
		override public function unserialize(data:Object):void
		{
			if( this.mClassId != data.type )
				throw new Error("bad args");
			
			this.x 			= data.x * Runtime.getInstance().sceneScalor;
			this.y 			= -data.y * Runtime.getInstance().sceneScalor;
			
			if( data.hasOwnProperty("sectionDelay") )
				this.mSectionDelay = data.sectionDelay;
			else 
				this.mSectionDelay = 1;
		}
		
		override public function serialize():Object
		{
			var obj:Object = new Object;
			obj.id 		= this.globalId;
			obj.type 	= this.mClassId;
			obj.x 		= Number( this.x / Runtime.getInstance().sceneScalor );
			obj.y 		= Number( -this.y / Runtime.getInstance().sceneScalor );
			
			obj.sectionDelay = this.mSectionDelay;
			
			return obj;
		}
		
		override public function get pos():Point 
		{
			return new Point( 
				Number( this.x / Runtime.getInstance().sceneScalor ),
				Number( -this.y / Runtime.getInstance().sceneScalor )
			);
		}
		
		public function get gameY():Number {
			return Number( -this.y/Runtime.getInstance().sceneScalor );
		}
		
		public function set triggeredTime(v:Number):void {
			this.mTriggeredTime = v;
		}
		public function get triggeredTime():Number {
			return this.mTriggeredTime;
		}
		
		public function set sectionDelay(v:Number):void {
			this.mSectionDelay = v;
		}
		
		public function get sectionDelay():Number {
			return this.mSectionDelay;
		}
		
		override public function select(value:Boolean):void
		{
			this.mUnderSelection = value;
			if( value && !this.mSelectedFrame )
			{
				this.mSelectedFrame = new Shape;
				this.mSelectedFrame.graphics.lineStyle(1, 0xff0000);
				this.mSelectedFrame.graphics.drawRect(
					-mSkin.width*0.5, -mSkin.height, mSkin.width, mSkin.height
				);
				this.addChild( this.mSelectedFrame );
				
				this.showTimeTriggerTips();
			}
			else if(!value && mSelectedFrame)
			{
				if( this.mShadowTips )
				{
					this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
					this.removeChild(mShadowTips);
					this.mShadowTips = null;
				}
				this.removeChild(mSelectedFrame);
				this.mSelectedFrame = null;
			}
		}
		
		public function showTimeTriggerTips():void
		{
			if(this.mTriggeredTime >= 0 && !this.mShadowTips)
			{
				this.mShadowTips = new Entity( this.mClassId, false );
				this.mShadowTips.setBaseSize( 50 );
				this.mShadowTips.alpha = 0.5;
				this.mShadowTips.x = 0;
				this.mShadowTips.y = 0;
				this.addChild(mShadowTips);
				this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			else if(this.mTriggeredTime < 0 && mShadowTips)
			{
				this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				this.removeChild(mShadowTips);
				mShadowTips = null;
			}
		}
		
		private function onEnterFrame(e:Event):void
		{
			if(this.mTriggeredTime>0 && mShadowTips)
			{
				this.mShadowTips.y = -this.mTriggeredTime/2-this.y;
			}
		}
		
		private static const STANDARD_WIDTH:Number = 100;
		private static const STANDARD_HEIGHT:Number = 100;
		
		override public function setBaseSize( value:Number  ):void
		{
			var scale:Number = Math.max( 
				value/Entity.STANDARD_WIDTH, 
				value/Entity.STANDARD_HEIGHT 
			);
			
			this.mSkin.scaleX = this.mSkin.scaleY = scale*this.mProfileScalor;
		}
		
		override public function setSize( value:Number ):void
		{
			var scale:Number = Math.min( 
				value/this.mSkin.width, 
				value/this.mSkin.height 
			);
			
			this.mSkin.scaleX = this.mSkin.scaleY = scale;
		}
		
		public function setTextTipsSize( value:Number ):void
		{
			if( this.mTextTips ) {
				var s:Number = Number(this.mTextTips.defaultTextFormat.size);
				if( s != 0 )
				{
					this.mTextTips.scaleX = this.mTextTips.scaleY =  value/s;
					this.mTextTips.x = -this.mTextTips.width/2;
				}
			}
		}
		
		public function setTextTipsVisible( value:Number ):void
		{
			
		}
	}
}