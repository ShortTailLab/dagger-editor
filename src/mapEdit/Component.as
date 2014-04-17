package mapEdit
{
	// interface
	import spark.core.SpriteVisualElement;
	public class Component extends SpriteVisualElement
	{
		public function dtor():void{};
		
		public function select(value:Boolean):void {}
		public function setBaseSize( value:Number  ):void {}
		public function unserialize(data:Object):void {}
		public function serialize():Object { return{}; }
		
		protected var mGlobalId:String = null;
		public function get globalId():String{ return this.mGlobalId; }
		public function set globalId(v:String):void { this.mGlobalId = v; }
		
		protected var mClassId:String = null;
		public function get classId():String { return this.mClassId; }
		
//		protected var mSubType:String = null;
//		public function get type():String { return this.mSubType; }
	}
}