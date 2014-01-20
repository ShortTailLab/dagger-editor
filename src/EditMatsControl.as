package
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import spark.primitives.Rect;
	
	import editEntity.EditBase;
	import editEntity.MatFactory;
	import editEntity.MatSprite;
	import editEntity.TriggerSprite;

	public class EditMatsControl
	{
		public var mats:Array;
		private var view:EditView;
		
		static private var idCount:int = 0;
		
		public function EditMatsControl(_view:EditView)
		{
			mats = new Array;
			view = _view;
		}
		
		public function init(data:Object):void
		{
			
			for each(var item:Object in data)
			{
				if(!item.hasOwnProperty("id"))
					item.id = getUID();
				
				var mat:EditBase = MatFactory.createMat(item.type, 30);
				mat.initFromData(item);
				addMat(mat);
			}
		}
		
		public function getMatsData():Array
		{
			var data:Array = new Array;
			for each(var m:EditBase in mats)
			{
				if(m.triggerId.length > 0 && !getMat(m.triggerId))
					m.triggerId = "";
					
				data.push(m.toExportData());
			}
			return data;
		}
		
		public function getMat(id:String):EditBase
		{
			for each(var m:EditBase in mats)
				if(m.id == id)
					return m;
			return null;
		}
		
		public function getMatByPoint(pos:Point):Array
		{
			var localPos:Point = view.map.globalToLocal(pos);
			var result:Array = new Array;
			for each(var m:EditBase in mats)
			{
				var bound:Rectangle = m.getBounds(m.parent);
				if(bound.contains(localPos.x, localPos.y))
					result.push(m);
			}
			return result;
		}
		
		public function add(type:String, px:int, py:int):EditBase
		{
			var mat:EditBase = MatFactory.createMat(type, 30);
			mat.x = px;
			mat.y = py;
			addMat(mat);
			return mat;
		}
		
		private function addMat(mat:EditBase):void
		{
			if(mat is TriggerSprite)
			{
				(mat as TriggerSprite).enableRectAdjust(true);
				(mat as TriggerSprite).active(view);
			}
			if(mat.id == "")
				mat.id = getUID();
			view.map.addChild(mat);
			mats.push(mat);
			view.listen(mat);	
		}
		
		private function getUID():String
		{
			return new Date().time+String(idCount++);;
		}
		
		public function remove(id:String):void
		{
			for(var i:int = 0; i < mats.length; i++)
				if(EditBase(mats[i]).id == id)
				{
					EditBase(mats[i]).onDelete();
					view.unlisten(mats[i]);
					view.map.removeChild(mats[i]);
					mats.splice(i, 1);
					break;
				}
		}
		
		public function clear():void
		{
			for each(var m:EditBase in mats)
				view.map.removeChild(m);
			mats.splice(0, mats.length);
		}
		

	}
}