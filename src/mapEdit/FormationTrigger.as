package mapEdit
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	import spark.core.SpriteVisualElement;
	
	public class FormationTrigger extends Component
	{
		private var dots:Vector.<Sprite> = new Vector.<Sprite>;
		
		public static const TRIGGER_TYPE:String = "FormationTrigger";
		private var mDotCorners:Vector.<Sprite> = null;
		
		private var mUnderSelection:Boolean 	= false;
		
		public function FormationTrigger()
		{
			this.mClassId = FormationTrigger.TRIGGER_TYPE;
			
			this.height = this.width = 100;
			this.x = this.y = 0;
			this.buildDefaultContent();
			
			this.addEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
		}
		
		private function buildDefaultContent():void
		{	
			this.mDotCorners = new Vector.<Sprite>;

			this.mDotCorners.push( buildADot(0, 0) );
			this.mDotCorners.push( buildADot(0, -100) );
			
			this.updateRect();
		}
		
		private function buildADot(px:Number, py:Number):Sprite
		{
			var dot:SpriteVisualElement = new SpriteVisualElement;
			dot.graphics.lineStyle(1);
			dot.graphics.beginFill(0x2222FF);
			dot.graphics.drawCircle(0, 0, 10);
			dot.graphics.endFill();
			
			with( dot ) { x = px; y = py; }
			this.addChild( dot );
			
			dot.addEventListener( MouseEvent.MOUSE_DOWN, this.onMouseDown );
			dot.addEventListener( MouseEvent.MOUSE_UP, 	 this.onMouseUp );
			dot.addEventListener( MouseEvent.MOUSE_OUT, this.onMouseUp );
			
			return dot;
		}
		
		private function updateRect():void
		{	
			this.x = 0;
			this.graphics.clear();
			this.graphics.lineStyle(2.5, 0x2222FF);
			this.graphics.moveTo(this.mDotCorners[0].x, this.mDotCorners[0].y);
			this.graphics.lineTo(this.mDotCorners[1].x, this.mDotCorners[1].y);
			this.graphics.endFill();
		}
		
		// --- > related data
		override public function unserialize(data:Object):void
		{
			var scalor:Number = Runtime.getInstance().sceneScalor;
			
			this.x = 0;
			this.y = -data.y*scalor-data.height*scalor/2;
			
			this.mDotCorners[0].x = 0; 
			this.mDotCorners[0].y = -data.height*scalor/2;
			
			this.mDotCorners[1].x = 0;
			this.mDotCorners[1].y = data.height*scalor/2;
			
			this.updateRect();
		}
		
		override public function serialize():Object
		{
			var bottom:int  = this.mDotCorners[0].y < this.mDotCorners[1].y ? 1 : 0;
			
			var scalor:Number = Runtime.getInstance().sceneScalor;
			var obj:Object 	= new Object;
			obj.type 		= FormationTrigger.TRIGGER_TYPE;
			obj.y 			= Number( -(this.y+this.mDotCorners[bottom].y) / scalor );
			obj.height 		= (this.mDotCorners[bottom].y-this.mDotCorners[1-bottom].y) / scalor ;
			
			return obj;
		}
		
		override public function select(value:Boolean):void
		{
			this.mUnderSelection = value;
			var color:uint = value ? 0xff5555 : 0x2222FF;
			var transform:ColorTransform = new ColorTransform;
			transform.color = color;
			this.transform.colorTransform = transform;
		}
		
		//		
		override public function setBaseSize( value:Number ):void
		{
			var scale:Number = value/this.width;
			this.scaleX = this.scaleY = scale;
		}
		
		override public function setSize( value:Number ):void
		{
			var scale:Number = Math.min( 
				value/this.width, 
				value/this.height 
			);
			this.scaleX = this.scaleY = scale;
		}
		
		private function onEnterFrame(e:*):void
		{	
			this.mDotCorners[0].x = this.mDotCorners[1].x = this.mFocusDot.x;
			this.updateRect();
		}
		
		private var mFocusDot:Sprite = null;
		private function onMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
			this.mFocusDot = e.currentTarget as Sprite;
			this.mFocusDot.startDrag();
			var self:FormationTrigger = this;
			this.stage.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
		}
		
		private function onMouseUp(e:MouseEvent):void
		{
			if( !this.mFocusDot ) return;

			e.stopPropagation();
			this.mFocusDot.stopDrag();
			this.mFocusDot = null;
			this.stage.removeEventListener(Event.ENTER_FRAME, this.onEnterFrame);
			this.mDotCorners[0].x = this.mDotCorners[1].x = 0;
			this.updateRect();
		}
	}
}