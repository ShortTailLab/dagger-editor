package mapEdit
{
	import com.hurlant.crypto.symmetric.NullPad;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	import spark.components.Group;
	import spark.core.SpriteVisualElement;

	public class AreaTriggerComponent extends Component
	{
		private var dots:Vector.<Sprite> = new Vector.<Sprite>;
		
		public static var TRIGGER_TYPE:String = "AreaTrigger";
		
		private var mRectangle:Rectangle 		= null;
		private var mDotCorners:Vector.<Sprite> = null;
		
		private var mInfoLayer:Sprite 			= null;
		private var mDotsOnMonster:Dictionary 	= null;
		
		public function AreaTriggerComponent(_editView:MainScene = null)
		{
			super(_editView, TRIGGER_TYPE);
			
			this.height = this.width = 100;
			this.mRectangle = new Rectangle(-50, -100, 100, 100);
			this.buildDefaultContent();
			
			this.mInfoLayer = new Sprite();
			this.mInfoLayer.visible = false;
			this.addChild( this.mInfoLayer );
			
			this.mDotsOnMonster = new Dictionary;
		}
		
		private function buildDefaultContent():void
		{	
			this.mDotCorners = new Vector.<Sprite>;
			// left-up
			this.mDotCorners.push( buildADot(this.mRectangle.x, 	this.mRectangle.y) );
			// right-up
			this.mDotCorners.push( buildADot(this.mRectangle.right, this.mRectangle.y) );
			// right-bottom
			this.mDotCorners.push( buildADot(this.mRectangle.right, this.mRectangle.bottom) );
			// leflt-bottom
			this.mDotCorners.push( buildADot(this.mRectangle.x, 	this.mRectangle.bottom) );
			
			this.updateRect();
		}
		
		private function buildADot(px:Number, py:Number):Sprite
		{
			var dot:SpriteVisualElement = new SpriteVisualElement;
			dot.graphics.lineStyle(1);
			dot.graphics.beginFill(0);
			dot.graphics.drawCircle(0, 0, 10);
			dot.graphics.endFill();
			
			with( dot ) { x = px; y = py; }
			this.addChild( dot );
			
			return dot;
		}
		
		private function updateRect():void
		{
			this.mRectangle.x 		= this.mDotCorners[0].x;
			this.mRectangle.y 		= this.mDotCorners[0].y;
			this.mRectangle.right 	= this.mDotCorners[2].x;
			this.mRectangle.bottom 	= this.mDotCorners[2].y;
			
			this.graphics.clear();
			this.graphics.lineStyle(1);
			this.graphics.beginFill(0xFFDDDD, 0.4);
			this.graphics.moveTo(this.mRectangle.x, 	this.mRectangle.y);
			this.graphics.lineTo(this.mRectangle.right, this.mRectangle.y);
			this.graphics.lineTo(this.mRectangle.right, this.mRectangle.bottom);
			this.graphics.lineTo(this.mRectangle.x, 	this.mRectangle.bottom);
			this.graphics.lineTo(this.mRectangle.x, 	this.mRectangle.y);
			this.graphics.endFill();
		}
		
		private function buildADot2(px:Number, py:Number):Sprite
		{
			var dot:SpriteVisualElement = new SpriteVisualElement;
			dot.graphics.lineStyle(1);
			dot.graphics.beginFill(0);
			dot.graphics.drawCircle(0, 0, 10);
			dot.graphics.endFill();
			
			with( dot ) { x = px; y = py; }
			
			return dot;
		}
		
		override public function initFromData(data:Object):void
		{
			this.sid = data.id;
			this.x = data.x/2 + data.width/4;
			this.y = -data.y/2 - data.height/4;
			this.mRectangle = new Rectangle(-data.width/4, -data.height/4, data.width/2, data.height/2);
			
			this.mDotCorners[0].x = this.mRectangle.x; 
			this.mDotCorners[0].y = this.mRectangle.y;
			
			this.mDotCorners[1].x = this.mRectangle.right;
			this.mDotCorners[1].y = this.mRectangle.y;
			
			this.mDotCorners[2].x = this.mRectangle.right;
			this.mDotCorners[2].y = this.mRectangle.bottom;
			
			this.mDotCorners[3].x = this.mRectangle.x;
			this.mDotCorners[3].y = this.mRectangle.bottom;
			
			for each ( var eid:String in data.objs )
			{
				var dot:Sprite = this.buildADot2(0, 0);
				var self:AreaTriggerComponent = this;
				dot.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
					e.stopPropagation();
					self.removeAMonster( eid );
					self.control( dot );
				});
				
				this.mInfoLayer.addChild( dot );
				this.mDotsOnMonster[eid] = dot;
			}
			
			this.updateRect();
		}
		
		override public function toExportData():Object
		{
			var obj:Object = new Object;
			obj.id = this.sid;
			obj.type = type;
			obj.x = (this.mRectangle.x+this.x)*2;
			obj.y = Number(-(this.mRectangle.bottom+this.y)*2);
			obj.width = this.mRectangle.width*2;
			obj.height = this.mRectangle.height*2;
			obj.objs = [];
			for( var key:* in this.mDotsOnMonster )
				obj.objs.push(key);
			
			return obj;
		}
		
		public function getSelectedMonsters():Array
		{
			var ret:Array = [];
			for( var key:* in this.mDotsOnMonster )
				ret.push(key);
			return ret;
		}
		
		override public function select(value:Boolean):void
		{
			this.mIsSelected = value;
			var color:uint = value ? 0xff0000 : 0;
			var transform:ColorTransform = new ColorTransform;
			transform.color = color;
			this.transform.colorTransform = transform;
			
			if( this.mAnchorDOT )
				this.mAnchorDOT.visible = this.mIsSelected;
			if( this.mInfoLayer )
				this.mInfoLayer.visible = this.mIsSelected;
		}
		
		private var mAnchorDOT:Sprite 		= null;
		private var mCtrlDOT:Sprite 		= null;
		private var mEnableEditing:Boolean 	= false;
		private var mMainScene:MainScene 	= null;
		public function enableEditing( scene:MainScene ):void
		{
			if( this.mEnableEditing ) return;
			else this.mEnableEditing = true;
			
			this.mMainScene = scene;
			
			for each ( var dot:Sprite in this.mDotCorners )
			{
				dot.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				dot.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			}
			
			var self:AreaTriggerComponent = this;
			this.mAnchorDOT = this.buildADot(0, 0);
			this.mAnchorDOT.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					if( self.mIsSelected )
					{
						e.stopPropagation();
						self.control( self.buildADot(0, -50) );
					}
				}
			);
			this.mAnchorDOT.visible = false;
			this.addChild( this.mAnchorDOT );
		
			this.addEventListener(Event.ENTER_FRAME, function(e:Event):void {

				self.mInfoLayer.graphics.clear();
				
				if( self.mCtrlDOT )
				{
					self.mInfoLayer.graphics.lineStyle(1, 0.5);
					self.mInfoLayer.graphics.moveTo(self.mAnchorDOT.x, self.mAnchorDOT.y);
					self.mInfoLayer.graphics.lineTo( self.mCtrlDOT.x,  self.mCtrlDOT.y);
				}
				for( var sid:String in self.mDotsOnMonster )
				{
					var entity:EntityComponent = self.mMainScene.getMonsterBySID( sid );
					if( !entity ) self.removeAMonster( sid );
					else {
						var pos:Point = self.globalToLocal(
							entity.parent.localToGlobal(new Point(entity.x, entity.y))
						);
						self.mDotsOnMonster[sid].x = pos.x;
						self.mDotsOnMonster[sid].y = pos.y;
		
						self.mInfoLayer.graphics.lineStyle(1, 0.5);
						self.mInfoLayer.graphics.moveTo(self.mAnchorDOT.x, self.mAnchorDOT.y);
						self.mInfoLayer.graphics.lineTo(pos.x, pos.y);
					}
				}
			});
		}
		
		private function control(target:Sprite):void
		{
			this.mCtrlDOT = target;
			this.mInfoLayer.addChild( target );
			this.stage.addEventListener(MouseEvent.MOUSE_UP, onControlMouseUp);
			target.startDrag();
		}
		
		private function onControlMouseUp(e:MouseEvent):void
		{
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, onControlMouseUp);
			
			this.mCtrlDOT.stopDrag();
			var globalPos:Point = this.mInfoLayer.localToGlobal(new Point(this.mCtrlDOT.x, this.mCtrlDOT.y));
			this.tryToCaputureAMonster( globalPos );
			
			this.mInfoLayer.removeChild(this.mCtrlDOT);
			this.mCtrlDOT = null;
		}
		
		private function tryToCaputureAMonster(globalPos:Point):void 
		{
			var entity:EntityComponent = this.mMainScene.getMonsterByPoint( globalPos );
			if( entity ) {
				if ( this.mDotsOnMonster.hasOwnProperty( entity.sid ) ) return;
				if ( entity.triggerId.length > 0 ) {
					Alert.show("【错误】已经有其他的区域触发器占用了这个敌人");
					return;
				}
				
				var dot:Sprite = this.buildADot2(0, 0);
				var self:AreaTriggerComponent = this;
				dot.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
					e.stopPropagation();
					self.removeAMonster( entity.sid );
					self.control( dot );
				});
				
				this.mInfoLayer.addChild( dot );
				this.mDotsOnMonster[entity.sid] = dot;
				
				entity.triggerId = this.sid;
			}
		}
		
		private function removeAMonster( sid:String ):void 
		{
			var entity:EntityComponent = this.mMainScene.getMonsterBySID( sid );
			if( entity ) entity.triggerId = "";
			if( this.mDotsOnMonster.hasOwnProperty( sid ) )
			{
				this.mInfoLayer.removeChild( this.mDotsOnMonster[sid] );
				delete this.mDotsOnMonster[sid];
			}
		}
//		
		override public function trim(size:Number):void
		{
			var scale:Number = size/this.width;
			this.scaleX = this.scaleY = scale;
		}
		
		private function onEnterFrame(e:*):void
		{	
			
			if( this.mFocusDot.x < 0 )
			{
				if( this.mFocusDot.y < 0 )
				{
					this.mDotCorners[0].x = this.mFocusDot.x;
					this.mDotCorners[0].y = this.mFocusDot.y;
					
					this.mDotCorners[1].x = -this.mFocusDot.x;
					this.mDotCorners[1].y = this.mFocusDot.y;
					
					this.mDotCorners[2].x = -this.mFocusDot.x;
					this.mDotCorners[2].y = -this.mFocusDot.y;
					
					this.mDotCorners[3].x = this.mFocusDot.x;
					this.mDotCorners[3].y = -this.mFocusDot.y;
				} else {
					this.mDotCorners[0].x = this.mFocusDot.x;
					this.mDotCorners[0].y = -this.mFocusDot.y;
					
					this.mDotCorners[1].x = -this.mFocusDot.x;
					this.mDotCorners[1].y = -this.mFocusDot.y;
					
					this.mDotCorners[2].x = -this.mFocusDot.x;
					this.mDotCorners[2].y = this.mFocusDot.y;
					
					this.mDotCorners[3].x = this.mFocusDot.x;
					this.mDotCorners[3].y = this.mFocusDot.y;
				}
			} else {
				if( this.mFocusDot.y < 0 ) 
				{
					this.mDotCorners[0].x = -this.mFocusDot.x;
					this.mDotCorners[0].y = this.mFocusDot.y;
					
					this.mDotCorners[1].x = this.mFocusDot.x;
					this.mDotCorners[1].y = this.mFocusDot.y;
					
					this.mDotCorners[2].x = this.mFocusDot.x;
					this.mDotCorners[2].y = -this.mFocusDot.y;
					
					this.mDotCorners[3].x = -this.mFocusDot.x;
					this.mDotCorners[3].y = -this.mFocusDot.y;
				} else {
					this.mDotCorners[0].x = -this.mFocusDot.x;
					this.mDotCorners[0].y = -this.mFocusDot.y;
					
					this.mDotCorners[1].x = this.mFocusDot.x;
					this.mDotCorners[1].y = -this.mFocusDot.y;
					
					this.mDotCorners[2].x = this.mFocusDot.x;
					this.mDotCorners[2].y = this.mFocusDot.y;
					
					this.mDotCorners[3].x = -this.mFocusDot.x;
					this.mDotCorners[3].y = this.mFocusDot.y;
				}
			}
			this.updateRect();
		}
		
		private var mFocusDot:Sprite = null;
		private function onMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
			this.mFocusDot = e.currentTarget as Sprite;
			this.mFocusDot.startDrag();
			var self:AreaTriggerComponent = this;
			this.stage.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
		}
		
		private function onMouseUp(e:MouseEvent):void
		{
			e.stopPropagation();
			this.mFocusDot = e.currentTarget as Sprite;
			this.mFocusDot.stopDrag();
			this.mFocusDot = null;
			this.stage.removeEventListener(Event.ENTER_FRAME, this.onEnterFrame);
			this.updateRect();
		}
	}
}