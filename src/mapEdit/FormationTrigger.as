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
	
	public class FormationTrigger extends Component
	{
		private var dots:Vector.<Sprite> = new Vector.<Sprite>;
		
		public static const TRIGGER_TYPE:String = "FormationTrigger";
		
		private var mDotCorners:Vector.<Sprite> = null;
		private var mUnderSelection:Boolean 	= false;
		private var mData:Object 				= {};
		private var mTargets:Object 			= [];
		
		public function FormationTrigger()
		{
			this.mClassId = FormationTrigger.TRIGGER_TYPE;
			
			this.height = this.width = 100;
			this.x = this.y = 0;
			
			this.buildDefaultContent();
			
			this.mInfoLayer = new Sprite();
			this.mInfoLayer.visible = false;
			this.addChild( this.mInfoLayer );
			
			this.mDotsOnMonster = {};
			
			this.addEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
		}
		
		private function buildDefaultContent():void
		{	
			this.mDotCorners = new Vector.<Sprite>;

			this.mDotCorners.push( buildADot(0, 50) );
			this.mDotCorners.push( buildADot(0, -50) );
			
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
			
			return dot;
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
		
		private function updateRect():void
		{	
			if( this.mAnchorDOT )
				this.mAnchorDOT.y = (this.mDotCorners[0].y+this.mDotCorners[1].y)/2;
			
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
			
			for each( var eid:String in data.targets )
			{
				var dot:Sprite = this.buildADot2(0, 0);
				var self:FormationTrigger = this;
				dot.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void 
				{
					e.stopPropagation();
					self.removeAMonster( eid );
					self.startCtrl( dot );
				});
				this.mInfoLayer.addChild( dot );
				this.mDotsOnMonster[eid] = dot;
			}
			
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
		
			var data:Object = {};
			var info:Array = Data.getInstance().dynamicArgs.Section || [];
			for each( var item:Array in info )
			{
				var key:String = item[ConfigPanel.kKEY];
				if( key in this.mData ) 
					data[key] = this.mData[key];
				else 
					data[key] = item[ConfigPanel.kDEFAULT];
			}
			
			obj.data = data;
			
			obj.targets = [];
			for( key in this.mDotsOnMonster )
				obj.targets.push(key);
			
			return obj;
		}
		
		override public function select(value:Boolean):void
		{
			this.mUnderSelection = value;
			var color:uint = value ? 0xff5555 : 0x2222FF;
			var transform:ColorTransform = new ColorTransform;
			transform.color = color;
			this.transform.colorTransform = transform;
			
			if( this.mAnchorDOT )
				this.mAnchorDOT.visible = this.mUnderSelection;
			if( this.mInfoLayer )
				this.mInfoLayer.visible = this.mUnderSelection;
		}
		
		private var mMainScene:MainScene 	= null;
		private var mInfoLayer:Sprite 		= null;
		private var mAnchorDOT:Sprite 		= null;
		private var mCtrlDOT:Sprite 		= null;
		private var mEnableEditing:Boolean 	= false;
		private var mDotsOnMonster:Object 	= {};
		public function enableEditing( scene:MainScene ):void
		{
			if( this.mEnableEditing ) return;
			this.mEnableEditing = true;
			
			var self:FormationTrigger = this;
			var menu:ContextMenu = new ContextMenu;
			
			var createMonster:ContextMenuItem = new ContextMenuItem("设定");
			createMonster.addEventListener(
				ContextMenuEvent.MENU_ITEM_SELECT, function(e:Event):void
				{
					var info:Array = Utils.deepCopy( Data.getInstance().dynamicArgs.Section ) as Array || [];
					for each( var item:Array in info )
					{
						if( item[ConfigPanel.kKEY] in self.mData ) 
							item[ConfigPanel.kDEFAULT] = self.mData[item[ConfigPanel.kKEY]];
					}
					
					var t:ConfigPanel = new ConfigPanel();
					t.init( function( configs:Object ):void {
						self.mData = configs;
					}, function(err:String):void{ Alert.show( err ); }, info, false, MapEditor.getInstance() );
				}
			);
			menu.addItem( createMonster );
			
			this.mMainScene = scene;
			for each( var dot:Sprite in this.mDotCorners )
			{
				dot.addEventListener( MouseEvent.MOUSE_DOWN, this.onMouseDown );
				dot.addEventListener( MouseEvent.MOUSE_UP, 	 this.onMouseUp );
				dot.addEventListener( MouseEvent.MOUSE_OUT, this.onMouseUp );
				dot.contextMenu = menu;
			}
			
			this.mAnchorDOT = this.buildADot2(0, (this.mDotCorners[0].y+this.mDotCorners[1].y)/2);
			this.mAnchorDOT.addEventListener(MouseEvent.MOUSE_DOWN,
				function( e:MouseEvent ):void {
					if( self.mUnderSelection ) 
					{
						e.stopPropagation();
						self.startCtrl( self.buildADot2( 0, 0 ) );
					}
				}
			);
			
			this.mAnchorDOT.addEventListener(MouseEvent.MOUSE_UP,
				function( e:MouseEvent ):void
				{
					if( self.mUnderSelection && self.mAnchorDOT )
					{
						e.stopImmediatePropagation()	
						self.endCtrl(null);
					}
				}
			);
			this.mAnchorDOT.visible = false;
			this.addChild( this.mAnchorDOT );
			
			this.addEventListener(Event.ENTER_FRAME, function(e:Event):void
			{
				self.mInfoLayer.graphics.clear();
				
				if( self.mCtrlDOT )
				{
					self.mInfoLayer.graphics.lineStyle( 1, 0.5 );
					self.mInfoLayer.graphics.moveTo( self.mAnchorDOT.x, self.mAnchorDOT.y);
					self.mInfoLayer.graphics.lineTo( self.mCtrlDOT.x,  self.mCtrlDOT.y);					
				}
				
				for( var sid:String in self.mDotsOnMonster )
				{
					var entity:Entity = self.mMainScene.getMonsterBySID( sid );
					if( !entity ) {
						self.removeAMonster( sid );
					}
					else {
						var pos:Point = self.globalToLocal(
							entity.parent.localToGlobal( new Point( entity.x, entity.y ) )
						);
						self.mDotsOnMonster[sid].x = pos.x;
						self.mDotsOnMonster[sid].y = pos.y;
						
						self.mInfoLayer.graphics.lineStyle(1, 0.5);
						self.mInfoLayer.graphics.moveTo( self.mAnchorDOT.x, self.mAnchorDOT.y );
						self.mInfoLayer.graphics.lineTo( pos.x, pos.y );
					}
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
				this.mCtrlDOT.removeEventListener(
					MouseEvent.MOUSE_UP, this.endCtrl
				);
			}	
		}
		
		private function startCtrl( target:Sprite ):void
		{
			this.mCtrlDOT = target;
			this.mInfoLayer.addChild( target );
			this.mCtrlDOT.addEventListener(MouseEvent.MOUSE_UP, this.endCtrl);
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
			var entity:Entity = this.mMainScene.getMonsterByPoint( globalPos );
			if( !entity ) return;
			
			if ( this.mDotsOnMonster.hasOwnProperty( entity.globalId ) ) return;
			if ( this.mMainScene.hasMonsterCaputuredByTrigger( entity.globalId ) )
			{
				Alert.show("【错误】该对象已被其他区域触发器所捕获!");
				return;
			}
			
			var dot:Sprite = this.buildADot2(0, 0);
			var self:FormationTrigger = this;
			dot.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {
				e.stopPropagation();
				self.removeAMonster( entity.globalId );
				self.startCtrl( dot );
			});
			
			this.mInfoLayer.addChild( dot );
			this.mDotsOnMonster[entity.globalId] = dot;
		}
		
		private function removeAMonster( sid:String ):void 
		{
			var entity:Entity = this.mMainScene.getMonsterBySID( sid );
			if( this.mDotsOnMonster.hasOwnProperty( sid ) )
			{
				this.mInfoLayer.removeChild( this.mDotsOnMonster[sid] );
				delete this.mDotsOnMonster[sid];
			}
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
			
			this.select( true );
		}
	}
}