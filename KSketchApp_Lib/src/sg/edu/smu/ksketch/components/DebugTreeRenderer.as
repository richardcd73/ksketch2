/**------------------------------------------------
* Copyright 2012 Singapore Management University
* All Rights Reserved
*
*-------------------------------------------------*/

package sg.edu.smu.ksketch.components
{
	import mx.controls.treeClasses.TreeItemRenderer;
	import mx.controls.treeClasses.TreeListData;
	
	public class DebugTreeRenderer extends TreeItemRenderer
	{
		public function DebugTreeRenderer()
		{
			super();
		}
		
		override public function set data(value:Object):void {
			super.data = value;
			var xml:XML = TreeListData(super.listData).item as XML;
			if(xml.@selected == "true")
			{
				setStyle("color", 0xff0000);
				setStyle("fontWeight", 'bold');
			}
			else
			{
				setStyle("color", 0x000000);
				setStyle("fontWeight", 'normal');
			}
		}
	}
}