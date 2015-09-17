package dol 
{
	import flash.utils.Dictionary;
	
	import debugger.Debugger;
	
	import fileUtils.FileData;
	
	import foozuu.app.AppConfig;

	public class DOLFormularChecker
	{
		protected var _formular:AppConfig;
		protected var _log:Object;
		public function DOLFormularChecker()
		{
			_formular = DOLFormular.ins.formular;
		}
		
		public function execute(list:Dictionary, clearLog:Boolean=true):*
		{
			if(clearLog==true)
				_log = null;
			
			var content:String = _formular.getData("folder_name_cant_match_anyone_in_rule");
			for (var root_name:String in list)
			{
				var rules:Object = checkRootNameValid(root_name);
				var lost:Object = null;
				//根目录匹配成功，继续检查子目录
				if(rules!=null)
				{
					var actions:Dictionary = getRuleActions(rules);
					for (var full_folder_path:String in list[root_name])
					{
						var files_list:Vector.<FileData> = Vector.<FileData>( list[root_name][full_folder_path] );
						if(files_list==null || files_list.length==0)
						{
							lost ||= new Object();
							lost[root_name] = _formular.getData("empty_folder");
							continue;
						}
						//如果目录可用，将该动作名标记为已找到，否则记录找不到目录
						var action_name:String = checkPathValid(full_folder_path, rules);
						if(action_name==null)
						{
							lost ||= new Object();
							lost[full_folder_path] = content;
							continue;
						}else{
							actions[action_name] = true;
						}
					}
					
					//遍历所有动作，如果有没被标记已找到，说明动作缺失
					for( action_name in actions)
					{
						if(actions[action_name]==false)
						{
							lost ||= new Object();
							lost[action_name] = _formular.getData("can_find_in_rule");
						}
					}
					
				}else{
					lost ||= new Object();
					lost[root_name] = content;
				}
				
				if(lost!=null)
					updateLost(root_name, lost);
			}
			if(_log!=null)
				Debugger.log(JSON.stringify(_log, null, 4));
			return _log;
		}
		
		protected function updateLost(key:String, value:*):void
		{
			if(_log==null)
				_log = new Object();
			_log[key] = value;
		}
		
		private function getRuleActions(rules:Object):Dictionary
		{
			var actions:Dictionary = new Dictionary();
			for (var action_key:String in rules.actions)
			{
				//找动作名
				var action_name:String = _formular.getData("actions")[action_key];
				if(rules!=null)
				{
					actions[action_name] = false;
				}
			}
			return actions;
		}
		
		/**
		 *检查根目录是否符合命名规范，如果符合，则返回该规范的规则 
		 * @param rootFolder
		 * @return 
		 * 
		 */		
		private function checkRootNameValid(rootFolder:String):*
		{
			var rules:Object = _formular.getData("rules");
			var root_reg:RegExp;
			var find:String;
			var char_name_rule_key:String = "char_name_rule";
			for (var root_name:String in rules)
			{
				root_reg = new RegExp(root_name);
				//根文件夹不匹配，不必继续
				find = root_reg.exec(rootFolder);
				if(find!=null)
				{
					var rule:Object = rules[root_name];
					var char_name_reg:RegExp;
					//检查有没有命名规则
					if(rule[char_name_rule_key]!=null)
					{
						char_name_reg = new RegExp(rule[char_name_rule_key]);
					}else if(_formular.getData(char_name_rule_key)!=null){
						char_name_reg = new RegExp(_formular.getData(char_name_rule_key));
					}
					//有命名规则，检查命名是否符合规则
					if(char_name_reg!=null)
					{
						var char_name_rule_find:String = char_name_reg.exec(rootFolder);
						//符合规则的视为可用
						if(char_name_rule_find!=null)
							return rule;
						//存在规则但是不符合，视为不可用
						else
							return null;
					}
					return rule;
				}
			}
			return null;
		}
		
		/**
		 *检查目录是否可用，如果可用返回该目录对应的动作名 
		 * @param path
		 * @param rules
		 * @return 
		 * 
		 */		
		private function checkPathValid(path:String, rules:Object):String
		{
			var action_name:String;
			var dir_name:String;
			var find_path:String;
			
			var find_action:String;
			var actions:Object = rules.actions;
			for (var action_key:* in actions)
			{
				//找动作名
				action_name = _formular.getData("actions")[action_key];
				dir_name = null;
				var directions:Array = actions[action_key];
				//尝试找方向名，有的动作可能没有方向，也许没有结果
				if(directions!=null)
				{
					for each(var dir:String in directions)
					{
						dir_name = _formular.getData("directions")[dir];
						if(dir_name!=null)
						{
							var action_name_temp:String = action_name.replace("^","");
							action_name_temp = action_name_temp.replace("$","");
							var dir_reg:RegExp = new RegExp(action_name_temp+"/" + dir_name+"$");
							find_path = dir_reg.exec(path);
							if(find_path!=null)
								return action_name;
						}
					}
				}else{
					var action_reg:RegExp = new RegExp(action_name);
					find_path = action_reg.exec(path);
					if(find_path!=null)
						return action_name;
				}
			}
			return null;
		}// e o f
	}
}