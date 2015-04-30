package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.text.TextFormat;
	
	import debugger.Debugger;
	
	import fl.controls.Label;
	import fl.controls.TextArea;
	import fl.core.UIComponent;
	import fl.events.SliderEvent;
	
	public class Png2Fla extends Sprite
	{
		protected var _panel:PanelSkin;
		protected var _workingPath:File;
		protected var _bCopying:Boolean;
		protected var _loader:Loader;
		protected var _executeCount:uint;
		
		protected const CONFIG:String = "import_config.txt";
		
		public function Png2Fla()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.color = 0x0099ff;

			_panel = new PanelSkin();
			addChild(_panel);
			_panel.addEventListener(MouseEvent.CLICK,  onMouseClick);
			_panel.copy_progress.minimum = 0;
			_panel.copy_progress.maximum = 1;
			
			var cfg:String = '{"x":"10","y":"200"}';
			var o:Object = JSON.parse(cfg);
			
			setAllTextSize(_panel, _panel.font_size.value);
			_panel.font_size.addEventListener(SliderEvent.CHANGE, onSliderHandler);
			updateState();
		}
		
		protected function onSliderHandler(event:SliderEvent):void
		{
			Debugger.log(_panel.font_size.minimum, _panel.font_size.maximum, _panel.font_size.value);
			setAllTextSize(_panel, _panel.font_size.value);
		}
		
		protected function onMouseClick(event:MouseEvent):void
		{
			switch(event.target)
			{
				case _panel.start:
				{
					start();
					break;
				}
				case _panel.select_path:
				{
					chooseWorkingPath();
					break;
				}
				case _panel.copy_config:
				{
					var source:File = File.applicationDirectory.resolvePath("templete/"+CONFIG);
					copyConfig(source, CONFIG, _workingPath.getDirectoryListing());
					break;
				}
			}
		}
		
		protected function start():void
		{
			if(_workingPath==null)
				return;
			log("========开始导图","00ff00");
			
			if(_loader==null)
			{
				_loader = new Loader();
				_panel.uiloader.source = _loader;
			}
			_panel.start.enabled = false;
			var children:Array = _workingPath.getDirectoryListing();
			
			_executeCount = 0;
			parseImages(children);
			log("本次处理文件数："+_executeCount);
			_panel.start.enabled = true;
			return;
			for each(var child:File in children)
			{
				if(child.isDirectory==false)
					continue;
				var cfg:File = child.resolvePath(CONFIG);
				if(cfg.exists==true)
				{
					Debugger.log(child.url);
				}else{
					log("该目录下不存在必要的配置文件，请检查："+child.nativePath,"ff0000");
				}
			}
		}
		
		protected function executeAllFolders(children:Array):void
		{
			if(children==null || children.length==0)
				return;
			var child:File = children.shift();
			if(child.isDirectory==false)
				return;
			var cfg:File = child.resolvePath(CONFIG);
			if(cfg.exists==true)
			{
				Debugger.log(child.url);
			}else{
				log("该目录下不存在必要的配置文件，请检查："+child.nativePath,"ff0000");
			}
		}
		
		protected function parseImages(children:Array):void
		{
			if(children==null || children.length==0)
				return;
			var child:File = children.shift();
			if(child==null)
				return;
			if(child.isDirectory==true)
				parseImages(child.getDirectoryListing());
			else
			{
				if(_panel.png.selected==true && child.extension==_panel.png.label)
				{
					_executeCount++;
					Debugger.log(child.extension, child.name);
					_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderHandler);
					_loader.load(new URLRequest(child.url));
				}
			}
			parseImages(children);
			
			function onLoaderHandler(event:Event):void
			{
				_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderHandler);
				_loader.unload();
				parseImages(children);
				log(child.name+" 完成。");
			}
		}
		
		/**
		 *拷贝sorce指定的文件到childrens包含的所有目录 
		 * @param source
		 * @param destPath
		 * @param childrens
		 * 
		 */		
		protected function copyConfig(source:File, destPath:String, children:Array):void
		{
			if(children==null || children.length==0)
				return;
			var child:File = children.shift();
			if(child==null)
				return;
			var dest:File = child.resolvePath(destPath);
			if(child.isDirectory==true)
			{
				Debugger.log(child.nativePath);
				source.copyToAsync(dest, _panel.override_copy.selected);
				source.addEventListener(Event.COMPLETE, onCopyHandler);
				source.addEventListener(IOErrorEvent.IO_ERROR, onCopyHandler);
			}else{
				Debugger.log(child.name);
				copyConfig(source, destPath, children);
			}
			
			function onCopyHandler(e:Event):void
			{
				source.removeEventListener(Event.COMPLETE, onCopyHandler);
				source.removeEventListener(IOErrorEvent.IO_ERROR, onCopyHandler);
				copyConfig(source, destPath, children);
				switch(e.type)
				{
					case IOErrorEvent.IO_ERROR:
					{
						log("该目录下配置文件可能已经存在:"+child.nativePath+"。或者请关闭编辑中的模板配置文件。","ff0000");
						break;
					}
					case Event.COMPLETE:
					{
						log("文件复制完成:"+child.nativePath+"","00ff00");
						break;
					}
				}
			}
		}
		
		protected function updateState():void
		{
			_panel.copy_config.enabled = _workingPath!=null ;//_panel.copy_progress.value==_panel.copy_progress.maximum 
			_panel.override_copy.enabled = _workingPath!=null;
			_panel.start.enabled = _workingPath!=null;
			_panel.current_path.text = _workingPath==null ? "请选择工作目录":_workingPath.nativePath;
		}
	
		/**
		 *打开工作目录 
		 * 
		 */		
		protected function chooseWorkingPath():void
		{
			var dir:File = File.applicationDirectory;
			dir.browseForDirectory("选择工作目录");
			dir.addEventListener(Event.SELECT, onWorkingPathSelected);
			dir.addEventListener(Event.CANCEL, onWorkingPathSelected);
		}
		
		/**
		 *选中工作目录 
		 * @param event
		 * 
		 */		
		protected function onWorkingPathSelected(event:Event):void
		{
			var dir:File = File.desktopDirectory;
			dir.removeEventListener(Event.SELECT, onWorkingPathSelected);
			dir.removeEventListener(Event.CANCEL, onWorkingPathSelected);
			_workingPath = event.target as File;
			
			switch(event.type)
			{
				case Event.CANCEL:
				{
					_workingPath = null;
					break;
				}
			}
			updateState();
			Debugger.log(_workingPath==null ? "unselected" : _workingPath.nativePath);
		}
		
		protected function getBitmapDataValidRect(bmd:BitmapData):Rectangle
		{
			var rect:Rectangle;
			if(bmd!=null)
			{
				rect = bmd.getColorBoundsRect(0xff000000,0xff000000, true);
			}else
			{
				rect = new Rectangle();
			}
			return rect;
		}
		
		protected function testBitmapData():void
		{
			var bmd:BitmapData = new Test()//new BitmapData(100,100,true,0x00ffffff);
			bmd.fillRect( new Rectangle(20,20,60,60), 0xffffff00);
			var bmp:Bitmap = new Bitmap(bmd, PixelSnapping.AUTO, true);
			addChild(bmp);
			var rect:Rectangle = getBitmapDataValidRect(bmd);
			trace(rect, bmp.getRect(this));
			graphics.beginFill(0xff00ff);
			graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
			graphics.endFill();
		}
		
		protected function executeScript():void
		{
			var path:String = "assets/export_feed_png.jsfl";
			path = "assets/icon.png"
			var file:File = File.applicationDirectory.resolvePath(path);
			trace(file.url);
			file.openWithDefaultApplication();
		}
		
		protected function log(content:String, color:String=null):void
		{
			content = "["+ (new Date()).toTimeString() +"] "+content;
			if(color!=null)
			{
				content = "<font color='#"+color+"'>"+ content+"</font>"
			}
			_panel.log.htmlText+=content;
			_panel.log.verticalScrollPosition = _panel.log.maxVerticalScrollPosition;
			//_panel.log.appendText(content);
		}
		
		
		private function setAllTextSize(container:DisplayObjectContainer, value:uint):void
		{
			if(container==null)
				return;
			var count:uint = container.numChildren;
			var index:uint = 0;
			while(index<count)
			{
				var child:DisplayObject = container.getChildAt(index);
				if(child is TextArea || child is Label)
				{
					UIComponent(child).setStyle("textFormat", new TextFormat("_sans", value));
				}else if(child is DisplayObjectContainer)
				{
					setAllTextSize(child as DisplayObjectContainer, value);
				}
				index++;
			}
		}
		
	}
}