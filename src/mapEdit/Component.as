package mapEdit
{
	// interface
	import spark.core.SpriteVisualElement;
	public class Component extends SpriteVisualElement
	{
		public function select(value:Boolean):void {}
		public function setBaseSize( value:Number  ):void {}
		public function unserialize(data:Object):void {}
		public function serialize():Object { return{}; }
		
		private var mGlobalId:String = null;
		public function get globalId():String{ return this.mGlobalId; }
		public function set globalId(v:String):void { this.mGlobalId = v; }
		
		protected var mType:String = null;
		public function get type():String { return this.mType; }
	}
}