package mapEdit
{
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	import spark.core.SpriteVisualElement;
	
	public class SectionManager extends Component
	{
		private var dots:Vector.<Sprite> = new Vector.<Sprite>;
		
		public static const TRIGGER_TYPE:String = "FormationTrigger";
		
		private var mUnderSelection:Boolean 	= false;
		private var mData:Object 				= {};
		private var mTargets:Object 			= [];
		
		private var mSectionEditor:EditSection 	= null;
		private var mSectionInd:String 			= null;
		
		private var mInfoLayer:Sprite 		= null;
		private var mTipsLayer:Sprite 		= null;
		
		private var mCtrlDOT:Sprite 		= null;
		private var mEnableEditing:Boolean 	= false;
		private var mDotsOnMonster:Object 	= {};
		
		public function SectionManager( editor:EditSection, ind:String )
		{
			this.mClassId = SectionManager.TRIGGER_TYPE;
			this.mSectionInd = ind;
			
			this.x = this.y = 0;
			
			this.buildDefaultContent();
			
			this.mInfoLayer = new Sprite();
			this.mInfoLayer.visible = false;
			this.addChild( this.mInfoLayer );
			
			this.mTipsLayer = new Sprite();
			this.mTipsLayer.visible = false;
			this.addChild( this.mTipsLayer );
			
			this.mDotsOnMonster = {};
			
			this.enableEditing( editor );
		}
		
		private function buildDefaultContent():void
		{	
			this.graphics.clear();
			this.graphics.lineStyle( 1 );
			this.graphics.beginFill( 0x2222FF );
			this.graphics.drawCircle( 0, 0, 15 );
			this.graphics.endFill();
		}
		
		private function buildADot2(px:Number, py:Number):Sprite
		{
			var dot:SpriteVisualElement = new SpriteVisualElement;
			dot.graphics.lineStyle(1);
			dot.graphics.beginFill(0x2222FF);
			dot.graphics.drawCircle(0, 0, 10);
			dot.graphics.endFill();
			
			with( dot ) { x = px; y = py; }
			return dot;
		}
		
		// --- > related data
		override public function unserialize(data:Object):void
		{
			var sidList:Array = data as Array, sid:String = null;
			for each( sid in sidList )
			{
				this.getAMonster( sid );
			}
		}
		
		override public function serialize():Object
		{
			var sid:String = null, ret:Array = [];
			for( sid in this.mDotsOnMonster )
				ret.push( sid );
			
			return ret as Object;
		}
		
		override public function select(value:Boolean):void
		{
			this.mUnderSelection = value;
			var color:uint = value ? 0xff5555 : 0x2222FF;
			var transform:ColorTransform = new ColorTransform;
			transform.color = color;
			this.transform.colorTransform = transform;
			
			if( this.mInfoLayer )
				this.mInfoLayer.visible = this.mUnderSelection;
			if( this.mTipsLayer )
				this.mTipsLayer.visible = this.mUnderSelection;
			
			if( value )
			{
				for( var sid:String in this.mDotsOnMonster )
				{
					var entity:Entity = this.mSectionEditor.getMonsterBySID( sid, this.mSectionInd );
					if( !entity ) {
						this.removeAMonster( sid );
					}
				}
				this.updateMonsterInfo();
			}
		}
		
		protected function updateMonsterInfo():void
		{
			this.mInfoLayer.graphics.clear();
			for( var sid:String in this.mDotsOnMonster )
			{
				var entity:Entity = this.mSectionEditor.getMonsterBySID( sid, this.mSectionInd );
				if( entity ) {
					var pos:Point = this.globalToLocal(
						entity.parent.localToGlobal( new Point( entity.x, entity.y ) )
					);
					this.mDotsOnMonster[sid].x = pos.x;
					this.mDotsOnMonster[sid].y = pos.y;
					
					this.mInfoLayer.graphics.lineStyle(1, 0.5);
					this.mInfoLayer.graphics.moveTo( 0, 0 );
					this.mInfoLayer.graphics.lineTo( pos.x, pos.y );
				}
			}
		}
		
		public function enableEditing( scene:EditSection ):void
		{
			if( this.mEnableEditing ) return;
			this.mEnableEditing = true;
			this.mSectionEditor = scene;

			var self:SectionManager = this;
			this.addEventListener(MouseEvent.MOUSE_DOWN,
				function( e:MouseEvent ):void {
					e.stopPropagation();
					if( self.mUnderSelection ) 
					{
						self.startCtrl( self.buildADot2( 0, 0 ) );
					}
					self.mSectionEditor.selectComponent( self );
				}
			);
			
			this.addEventListener(MouseEvent.MOUSE_UP,
				function( e:MouseEvent ):void
				{
					if( self.mUnderSelection )
					{
						e.stopImmediatePropagation()	
						self.endCtrl(null);
					}
				}
			);
			
			this.addEventListener(Event.ENTER_FRAME, function(e:Event):void
			{
				self.mTipsLayer.graphics.clear();
				
				if( self.mCtrlDOT )
				{
					self.mTipsLayer.graphics.lineStyle( 1, 0.5 );
					self.mTipsLayer.graphics.moveTo( 0, 0);
					self.mTipsLayer.graphics.lineTo( self.mCtrlDOT.x,  self.mCtrlDOT.y);					
				}
			});
			
			Runtime.getInstance().addEventListener( Runtime.CANCEL_SELECTION, function(e:Event):void
			{
				self.select( false );
			});
		}
		
		override public function dtor():void
		{
			// clean up
			if( this.mCtrlDOT )
			{
				this.stage.removeEventListener(
					MouseEvent.MOUSE_UP, this.endCtrl
				);
			}	
		}
		
		private function startCtrl( target:Sprite ):void
		{
			if( this.mCtrlDOT ) return;
			this.mCtrlDOT = target;
			this.mInfoLayer.addChild( target );
			this.stage.addEventListener(MouseEvent.MOUSE_UP, this.endCtrl);
			target.startDrag();
		}
		
		private function endCtrl( e:MouseEvent ):void
		{
			if( !this.mCtrlDOT ) return;
			this.stage.removeEventListener( MouseEvent.MOUSE_UP, this.endCtrl );
			
			this.mCtrlDOT.stopDrag();
			var globalPos:Point = this.mInfoLayer.localToGlobal( 
				new Point( this.mCtrlDOT.x, this.mCtrlDOT.y )
			);
			this.tryToCaputureAMonster( globalPos );
			
			this.mInfoLayer.removeChild( this.mCtrlDOT );
			this.mCtrlDOT = null;
		}
		
		private function tryToCaputureAMonster(globalPos:Point):void 
		{	
			var entity:Entity = this.mSectionEditor.getMonsterByPoint( globalPos, this.mSectionInd );
			if( !entity ) return;
			
			if ( this.mDotsOnMonster.hasOwnProperty( entity.globalId ) ) return;
			
			this.getAMonster( entity.globalId );
		}
		
		private function getAMonster( sid:String ):void
		{
			var dot:Sprite = this.buildADot2(0, 0);
			var self:SectionManager = this;
			dot.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
				e.stopPropagation();
				self.removeAMonster( sid );
				self.startCtrl( dot );
			});
			
			this.mInfoLayer.addChild( dot );
			this.mDotsOnMonster[sid] = dot;
			this.updateMonsterInfo();
		}
		
		private function removeAMonster( sid:String ):void 
		{
			if( this.mDotsOnMonster.hasOwnProperty( sid ) )
			{
				this.mInfoLayer.removeChild( this.mDotsOnMonster[sid] );
				delete this.mDotsOnMonster[sid];
			}
			this.updateMonsterInfo();
		}
		
		public function isMonsterIn( sid:String ):Boolean
		{
			if( this.mDotsOnMonster.hasOwnProperty( sid ) )
				return true;
			return false;
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
		
		private var mFocusDot:Sprite = null;
		private function onMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
			this.mFocusDot = e.currentTarget as Sprite;
			this.mFocusDot.startDrag();
		}
		
		private function onMouseUp(e:MouseEvent):void
		{
			if( !this.mFocusDot ) return;

			e.stopPropagation();
			this.mFocusDot.stopDrag();
			this.mFocusDot = null;
			
			if( this.mSectionEditor )
				this.mSectionEditor.selectComponent( this );
		}
	}
}