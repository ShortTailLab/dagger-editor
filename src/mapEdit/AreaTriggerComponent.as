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
		private var rect:Rectangle = null;
		public var beginTriDot:Sprite = null;
		public var triggerMatIds:Array = null;
		public var dotsDic:Dictionary = null;
		private var triggerLayer:Sprite;
		private var editable:Boolean = false;
		
		private var mRectangle:Rectangle 		= null;
		private var mDotCorners:Vector.<Sprite> = null;
		
		private var mInfoLayer:Sprite 			= null;
		private var mDotsOnMonster:Dictionary 	= null;
		
		private var mTargetMonsters:Array 		= null;
		
		public function AreaTriggerComponent(_editView:MainScene = null)
		{
			super(_editView, TRIGGER_TYPE);
			
			//左上角为原点
			rect = new Rectangle(-50, -100, 100, 100);
			triggerMatIds = new Array;
			dotsDic = new Dictionary;
//			initRectDots();
			this.height = this.width = 100;
//			
			this.mRectangle = new Rectangle(-50, -100, 100, 100);
			this.buildDefaultContent();
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
		
		override public function select(value:Boolean):void
		{
			this.mIsSelected = value;
			var color:uint = value ? 0xff0000 : 0;
			var transform:ColorTransform = new ColorTransform;
			transform.color = color;
			this.transform.colorTransform = transform;
			
			this.mAnchorDOT.visible = this.mIsSelected;
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
			this.mAnchorDOT = this.buildADot(0, -50);
			this.mAnchorDOT.addEventListener(MouseEvent.MOUSE_DOWN,
				function(e:MouseEvent):void {
					if( self.mIsSelected )
					{
						e.stopPropagation();
						self.control( self.buildADot(0, -50) );
					}
				}
			);
			this.addChild( this.mAnchorDOT );
			
			this.mInfoLayer = new Sprite();
			this.addChild( this.mInfoLayer );
			
			this.mDotsOnMonster = new Dictionary;
			this.mTargetMonsters = [];
			
			this.addEventListener(Event.ENTER_FRAME, function(e:Event):void {
				for each( var dot:Sprite in this.mDotsOnMonster )
				{
					
				}
			});
		}
		
		private function control(target:Sprite):void
		{
			this.mCtrlDOT = target;
			this.mInfoLayer.addChild( target );
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, onControlMouseMove);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, onControlMouseUp);
			target.startDrag();
		}
		
		private function onControlMouseMove(e:MouseEvent):void 
		{
			
		}
		
		private function onControlMouseUp(e:MouseEvent):void
		{
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onControlMouseMove);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, onControlMouseUp);
			
			this.mCtrlDOT.stopDrag();
			var globalPos:Point = this.mInfoLayer.localToGlobal(new Point(this.mCtrlDOT.x, this.mCtrlDOT.y));
			this.tryToCaputureAMonster( globalPos );
			
			this.mInfoLayer.removeChild(this.mCtrlDOT);
			this.mCtrlDOT = null;
		}
		
//		public function initTriggerMats():void
//		{
//			for each(var id:String in triggerMatIds)
//			{
//				var dot:Sprite = createDot();
//				dot.addEventListener(MouseEvent.MOUSE_DOWN, onTirggerDotMouseDown);
//				triggerLayer.addChild(dot);
//				dotsDic[id] = dot;
//			}
//		}
		
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
				this.mInfoLayer.addChild( dot );
				this.mDotsOnMonster[entity.sid] = dot;
				this.mTargetMonsters.push( entity.sid );
				
				entity.triggerId = this.sid;
			}
		}

		private function onTirggerDotMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
			for(var id:* in dotsDic)
				if(dotsDic[id] == e.currentTarget)
				{
//					controlDot = dotsDic[id];
//					control(controlDot);
					removeATrigger(id);
					return;
				}
		}
		
		public function removeATrigger(id:String):void
		{
			for(var i:int = 0; i < triggerMatIds.length; i++)
				if(triggerMatIds[i] == id)
				{
					triggerMatIds.splice(i, 1);
					delete dotsDic[id];
					break;
				}
		}
//		
		override public function trim(size:Number):void
		{
			var scale:Number = size/this.width;
			this.scaleX = this.scaleY = scale;
		}
		
		override public function initFromData(data:Object):void
		{
			this.sid = data.id;
			this.x = data.x/2;
			this.y = -data.y/2;
			this.rect = new Rectangle(0, -data.height, data.width, data.height);
			this.triggerMatIds = data.objs as Array;
			
			this.updateRect();
		}
		
		override public function toExportData():Object
		{
			var obj:Object = new Object;
			obj.id = this.sid;
			obj.type = type;
			obj.x = (rect.x+this.x)*2;
			obj.y = Number(-(rect.bottom+this.y)*2);
			obj.width = rect.width;
			obj.height = rect.height;
			obj.objs = triggerMatIds;
			return obj;
		}
		
		public function render():void
		{	
			if(editable)
			{
				beginTriDot.x = rect.x+rect.width*0.5;
				beginTriDot.y = rect.y+rect.height*0.5;
				
				triggerLayer.graphics.clear();
//				if(controlDot)
//				{
//					triggerLayer.graphics.lineStyle(1, 0.5);
//					triggerLayer.graphics.moveTo(beginTriDot.x, beginTriDot.y);
//					triggerLayer.graphics.lineTo(controlDot.x, controlDot.y);
//				}
				for(var id in dotsDic)
				{
//					var mat:Component = editView.matsControl.getMat(id);
//					if(mat)
//					{
//						var pos:Point = this.globalToLocal(mat.parent.localToGlobal(new Point(mat.x, mat.y)));
//						dotsDic[id].x = pos.x;
//						dotsDic[id].y = pos.y;
//						triggerLayer.graphics.lineStyle(1, 0.5);
//						triggerLayer.graphics.moveTo(beginTriDot.x, beginTriDot.y);
//						triggerLayer.graphics.lineTo(pos.x, pos.y);
//					}
//					else
					{
						removeATrigger(id);
					}
				}
			}
			
		}
		
		private function onEnterFrame(e:*):void
		{	
			if( this.mFocusDot == this.mDotCorners[0] )
			{
				this.mDotCorners[1].y = this.mFocusDot.y;
				this.mDotCorners[3].x = this.mFocusDot.x;
			}
			else if( this.mFocusDot == this.mDotCorners[1] ) 
			{
				this.mDotCorners[2].x = this.mFocusDot.x;
				this.mDotCorners[0].y = this.mFocusDot.y;
			}
			else if( this.mFocusDot == this.mDotCorners[2] ) 
			{
				this.mDotCorners[1].x = this.mFocusDot.x;
				this.mDotCorners[3].y = this.mFocusDot.y;
			}
			else if ( this.mFocusDot == this.mDotCorners[3] ) 
			{
				this.mDotCorners[0].x = this.mFocusDot.x;
				this.mDotCorners[2].y = this.mFocusDot.y;
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