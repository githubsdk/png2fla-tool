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
		
		public function execute(list:Dictionary, publishConfigs:Dictionary, clearLog:Boolean=true):*
		{
			if(clearLog==true)
				_log = null;
			
			var folder_name_cant_match_anyone_in_rule:String = _formular.getData("folder_name_cant_match_anyone_in_rule");
			var can_find_action_in_publish_config:String =  _formular.getData("can_find_action_in_publish_config");
			var can_find_publish_config:String = _formular.getData("can_find_publish_config");
			var default_value:String = _formular.getData("default_value");
			var empty_folder:String = _formular.getData("empty_folder");
			var cant_find_in_rule:String = _formular.getData("cant_find_in_rule");
			
			for (var root_name:String in list)
			{
				var rules:Object = checkRootNameValid(root_name);
				var errors:Array;
				
				var publish_config:Object = publishConfigs[root_name];
				if(publish_config==null)
				{
					updateLost(root_name, can_find_publish_config, root_name);
				}else{
					var defalut_value_error:Array = configValueCheck(_formular.getData("config_rules"), publish_config.charfolder);
					if(defalut_value_error!=null)
					{
						updateLost(root_name, default_value, defalut_value_error);
					}
				}
				
				//根目录匹配成功，继续检查子目录
				if(rules!=null)
				{
					var actions:Dictionary = getRuleActions(rules);
					for (var full_folder_path:String in list[root_name])
					{
						var files_list:Vector.<FileData> = Vector.<FileData>( list[root_name][full_folder_path] );
						if(files_list==null || files_list.length==0)
						{
							updateLost(root_name, empty_folder, full_folder_path);
							continue;
						}
						//如果目录可用，将该动作名标记为已找到，否则记录找不到目录
						var check_result:Array = checkPathValid(full_folder_path, rules);
						if(check_result==null)
						{
							updateLost(root_name, folder_name_cant_match_anyone_in_rule, full_folder_path);
							continue;
						}else{
							actions[check_result[0]] = true;
							if(publish_config!=null)
							{
								var action_config_data:Object = publish_config.charfolder.labels[ check_result[1] ];
								if(action_config_data!=null)
								{
									var error_obj:Object = actionDefaultValueCheck(check_result[1], check_result[2], action_config_data);
									if(error_obj!=null)
									{
										updateLost(root_name, default_value, error_obj);
									}
								}
								else
								{
									updateLost(root_name, can_find_action_in_publish_config, check_result[1]);
								}
							}
							
						}
					}
					
					//遍历所有动作，如果有没被标记已找到，说明动作缺失
					for( var action_name:* in actions)
					{
						if(actions[action_name]==false)
						{
							updateLost(root_name, cant_find_in_rule, action_name);
						}
					}
					
				}else{
					updateLost(root_name, folder_name_cant_match_anyone_in_rule, root_name);
				}
			}

			if(_log!=null)
				Debugger.log(JSON.stringify(_log, null, 4));
			return _log;
		}
		
		private function actionDefaultValueCheck(actionName:String, actionIndex:* , folderConfig:Object):Object
		{
			if(folderConfig==null)
				return null;
			var rules_config:Object = _formular.getData("config_rules");
			var errors:Array ;
			errors = configValueCheck(rules_config.labels[actionIndex], folderConfig);
			if(errors!=null)
			{
				var e:Object = new Object();
				e[actionName] = errors;
				return e;
			}
			return null;
		}
		
		private function configValueCheck(source:Object, config:Object, simpleCheck:Boolean=true):Array
		{
			var errors:Array;
			if(config==null)
				return errors;
			for (var key:* in source)
			{
				errors ||= new Array();
				var value:* = source[key];
				//只检查简单对象
				if(ObjectUtils.checkSimpleObject(value)==true)
				{
					if(config[key]==null || config[key]==source[key])
					{
						var temp_error:Object = new Object();
						temp_error[key] = source[key];
						errors.push(temp_error);
					}
				}else if(simpleCheck==false)
				{
					errors ||= new Array();
					errors = errors.concat( configValueCheck(source[key], config[key], simpleCheck) );
				}
			}
			
			return errors;
		}
		
		protected function updateLost(key:String, type:String, value:*):void
		{
			if(_log==null)
				_log = new Object();
			var key_data:Object = _log[key];
			if(key_data==null)
				key_data = _log[key] = new Object();
			var errors:Array = key_data[type];
			if(errors==null)
				errors = key_data[type] = new Array();
			errors.push(value);
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
		private function checkPathValid(path:String, rules:Object):Array
		{
			var action_name:String;
			var dir_name:String;
			var find_action:String;
			var actions:Object = rules.actions;
			for (var action_key:* in actions)
			{
				//找动作名
				action_name = _formular.getData("actions")[action_key];
				dir_name = null;
				var directions:Array = actions[action_key];
				var action_reg:RegExp;
				var action_reg_exe:Array;
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
							if(dir_reg.exec(path)!=null)
							{
								action_reg = new RegExp(action_name_temp);
								action_reg_exe = action_reg.exec(path);
								return [action_name, action_reg_exe[0], action_key ];
							}
						}
					}
				}else{
					action_reg = new RegExp(action_name);
					action_reg_exe = action_reg.exec(path);
					if(action_reg_exe!=null)
						return [action_name, action_reg_exe[0], action_key];
				}
			}
			return null;
		}// e o f
	}
}