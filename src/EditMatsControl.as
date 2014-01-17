package
{
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
				var mat:MatSprite = new MatSprite(item.type, -1, 30);
				mat.initFromData(item);
				addMat(mat);
			}
		}
		
		public function getMatsData():Array
		{
			var data:Array = new Array;
			for each(var m:MatSprite in mats)
			data.push(m.toExportData());
			return data;
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
				(mat as TriggerSprite).enable(true);
			mat.id = idCount++;
			view.map.addChild(mat);
			mats.push(mat);
			view.listen(mat);	
		}
		
		public function remove(id:int):void
		{
			for(var i:int = 0; i < mats.length; i++)
				if(EditBase(mats[i]).id == id)
				{
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