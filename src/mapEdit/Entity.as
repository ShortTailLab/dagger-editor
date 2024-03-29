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
		private var mStartDelay:Number 	= 1;
		private var mDelay:Number 		= 1;
		private var mTeamNumber:String 	= null;
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
			
			this.x 			= data.x * EditSection.kSceneScalor;
			this.y 			= EditSection.kSceneHeight - data.y * EditSection.kSceneScalor;
			this.globalId 	= data.id;
			
			if( data.hasOwnProperty("startDelay") )
				this.mStartDelay = data.startDelay;
			else 
				this.mStartDelay = 1;
			
			if( data.hasOwnProperty("delay") )
				this.mDelay = data.delay;
			else 
				this.mDelay = 1;
			
			if( data.hasOwnProperty("team") )
				this.mTeamNumber = data.team;
			else 
				this.mTeamNumber = null;
		}
		
		override public function serialize():Object
		{
			var obj:Object = new Object;
			
			obj.id 		= this.globalId;
			obj.type 	= this.mClassId;
			
			obj.x 		= this.x/EditSection.kSceneScalor;
			obj.y 		= (EditSection.kSceneHeight-this.y)/EditSection.kSceneScalor;
			
			obj.startDelay 	= this.mStartDelay;
			obj.delay 		= this.mDelay;
			if( this.mTeamNumber && this.mTeamNumber != "null" )
				obj.team 		= this.mTeamNumber;
			
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
		
		public function set startDelay(v:Number):void {
			this.mStartDelay = v;
		}
		
		public function get startDelay():Number {
			return this.mStartDelay;
		}
		
		public function set delay(v:Number):void {
			this.mDelay = v;
		}
		
		public function get delay():Number {
			return this.mDelay;
		}
		
		public function set teamNumber(v:String):void
		{
			if( !v  || v == "" || v == "null" ) this.mTeamNumber = null;
			else 
				this.mTeamNumber = v;
		}
		
		public function get teamNumber():String
		{
			return this.mTeamNumber;
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
			}
			else if(!value && mSelectedFrame)
			{
				if( this.mShadowTips )
				{
					this.removeChild(mShadowTips);
					this.mShadowTips = null;
				}
				this.removeChild(mSelectedFrame);
				this.mSelectedFrame = null;
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