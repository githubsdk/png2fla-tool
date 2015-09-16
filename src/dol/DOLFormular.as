package dol
{
	import flash.desktop.NativeApplication;
	import flash.filesystem.File;
	
	import foozuu.app.AppConfig;

	public class DOLFormular
	{
		static private var _ins:DOLFormular;
		
		protected var _formular:AppConfig;
		
		public function DOLFormular()
		{
			_formular = new AppConfig(NativeApplication.nativeApplication, File.applicationDirectory.resolvePath("addons/check_formular.json").url);
		}

		public static function get ins():DOLFormular
		{
			_ins ||= new DOLFormular();
			return _ins;
		}

		public function get formular():AppConfig
		{
			return _formular;
		}


	}
}