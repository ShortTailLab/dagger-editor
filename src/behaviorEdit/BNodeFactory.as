package behaviorEdit
{
	public class BNodeFactory
	{
		static var numCount:int = 0;
		
		static public function createBNode(type:String):BNode
		{
			var node:BNode = null;
			if(type == BType.BTYPE_BASIC)
				node = new BNode;
			else if(type == BType.BTYPE_SEQ)
				node = new SeqBNode;
			else if(type == BType.BTYPE_ROOT)
				node = new RootBNode;
			else if(type == BType.BTYPE_EXEC)
				node = new ExecBNode();
			if(node)
				node.id = numCount++;
			return node;
		}
	}
}