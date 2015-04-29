package ini
{
	public class IniFile
	{
		private var _content:String;
		
		public function IniFile(content:String=null)
		{
			init(content);
		}
		
		public function init(content:String):void
		{
			_content = content;
			JSON.parse("");
		}
		
		public function getValue(key:String):Object
		{
			
			return null;
		}
	}
}