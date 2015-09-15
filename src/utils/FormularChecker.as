package utils
{
	import flash.desktop.NativeApplication;
	import flash.filesystem.File;
	
	import fileUtils.FileData;
	
	import foozuu.app.AppConfig;

	public class FormularChecker
	{
		protected var _formular:Object;
		public function FormularChecker()
		{
			_formular = new AppConfig(NativeApplication.nativeApplication, File.applicationDirectory.resolvePath("addons/check_formular.json").url);
		}
		
		public function execute(list:Vector.<FileData>):*
		{
			
			return null;
		}
	}
}