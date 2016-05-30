--动画系统
--2015/10/26 高凯
--内置，简单，稳定，可拓展，支持UGUI的lua动画系统

--=================================================>> 参数和数据 <<============================================= START
	
	--全局常量
		--动画类型
		c_anchoredPosition = "anchoredPosition";
		c_localScale       = "localScale";
		c_UGUI_alpha       = "UGUI_alpha"; -- 该动画会将该节点下所有Image的alpha改变
		c_position         = "position";
		c_particle_alpha   = "particle_alpha"; -- 该动画会将该节点下所有粒子系统的start color改变
		c_UGUI_sizeDelta   = "UGUI_sizeDelta";

		--插值算法类型
		c_interArithmetic_Lerp       = "Lerp";

		c_interArithmetic_inQuad     = "inQuad";
		c_interArithmetic_outQuad    = "outQuad";
		c_interArithmetic_inOutQuad  = "inOutQuad";
		c_interArithmetic_outInQuad  = "outInQuad";

		c_interArithmetic_inBack     = "easeInBack";
		c_interArithmetic_outBack    = "easeOutBack";
		c_interArithmetic_inOutBack  = "easeInOutBack";
		c_interArithmetic_outInBack  = "easeOutInBack";

		c_interArithmetic_inCubic    = "inCubic";
		c_interArithmetic_outCubic   = "outCubic";
		c_interArithmetic_inOutCubic = "inOutCubic";
		c_interArithmetic_outInCubic = "outInCubic";

		c_interArithmetic_customOne  = "customOne";
		c_interArithmetic_NewUIAnim  = "NewUIAnim";

	--内部数据
	local t_animList = {}; --所有动画数据

	local n_easeParameter = 0.8;   --缓动参数
	local x_calcValue     = nil;   --动画系统计算出来的值
--=================================================>> 参数和数据 <<=============================================  END

--=================================================>> 外部调用函数 <<=========================================== START

	--初始化动画系统
		--（model文件 初始化调用）
	function initAnimSystem_AnimSystem()

		-- 事件注册
		E:Add(eventName.change_scence,receviceChangeScence_AnimSystem);
	end

	--更新每个对象的值,由update直接调用,传入的是帧间隔,单位毫秒,(高频线程，请尽量避免使用复杂的函数)
		--（由C#调用）
	function updateAnimSyetem_AnimSystem(n_deltaTime)

		for n_key,t_animInfo in pairs(t_animList) do

			t_animInfo.n_proceedTime = t_animInfo.n_proceedTime + n_deltaTime;

			if t_animInfo.n_proceedTime > t_animInfo.n_time then
				t_animInfo.n_proceedTime = t_animInfo.n_time;
			end

			-- 计算出目标值
			x_calcValue = calcValue_AnimSystem(t_animInfo);

			-- warn("x_calcValue: "..x_calcValue);
			-- warn("t_animInfo.n_proceedTime :"..tostring(t_animInfo.n_proceedTime));
			-- warn("t_animInfo.n_time :"..tostring(t_animInfo.n_time));

			--应用目标值
			changeValue_AnimSystem(t_animInfo,t_animInfo.s_parameterType,x_calcValue); 

			-- warn("应用目标值");

			--动画完成
			if t_animInfo.n_proceedTime >= t_animInfo.n_time then 

				-- warn("动画完成 0");

				t_animList[n_key] = nil;

				-- warn("动画完成");

				-- warn(t_animInfo.f_endCallBack);

				--动画播放完毕回调
				if t_animInfo.f_endCallBack ~= nil then
					local b_callBackResult,s_errorMasssage = pcall(t_animInfo.f_endCallBack , t_animInfo.x_endCallBackParameter);
				    if not b_callBackResult then
				        error("AnimSystem finish CallBack error ："..tostring(s_errorMasssage).." ");
				        print_r(t_animInfo);
				    end
				end
			end
		end
	end

	--场景切换，清除所有动画
		--（场景切换时调用）
	function receviceChangeScence_AnimSystem()

		for k,v in pairs(t_animList) do
			if IsNil(v.go_animObj)  == false then
				destroy(v.go_animObj);
			end
		end

		t_animList = {};
	end

	--添加动画
		--（需要时调用）
		--要执行动画的游戏物体
		--动画类型
		--初始值（可空）
		--结束值
		--动画时间
		--插值算法（可空，默认线性插值）
		--动画播放完毕回调（可空）
		--动画播放完毕回调传参（可空）
	function AnimTo_AnimSystem( go_animObj,s_parameterType,x_parameter1,x_parameter2,n_time,s_interArithmeticType,f_endCallBack,x_endCallBackParameter)

		--输入检测
			--非空判断
		if go_animObj      == nil then error("go_animObj      is nil ! by AnimSystem.moveTo"); return end
		if x_parameter2    == nil then error("x_parameter2    is nil ! by AnimSystem.moveTo"); return end
			--非空判断和类型判断
		if s_parameterType == nil or type(s_parameterType) ~= "string" then 
			error("s_parameterType parameter error ! by AnimSystem.moveTo s_parameterType is "..tostring(s_parameterType).." type is "..type(s_parameterType) ); return end
		if n_time          == nil or type(n_time) ~= "number" then 
			error("n_time          parameter error ! by AnimSystem.moveTo n_time is "..tostring(n_time).."type is"..type(n_time)); return end
		if type(f_endCallBack) ~= "nil" and type(f_endCallBack) ~= "function" then
			error("f_endCallBack is not function! place check forget s_interArithmeticType ?") return end

		--默认线性插值
		if s_interArithmeticType == nil then
			s_interArithmeticType = c_interArithmetic_Lerp;
		end

		--储存数据
		local t_animInfo = {};
			  t_animInfo.go_animObj             = go_animObj;
			  t_animInfo.s_parameterType        = s_parameterType;
			  t_animInfo.x_parameter1           = x_parameter1;
			  t_animInfo.x_parameter2           = x_parameter2;
			  t_animInfo.n_time                 = n_time;
			  t_animInfo.s_interArithmeticType  = s_interArithmeticType;
			  t_animInfo.com_subCom             = getCom_AnimSystem(go_animObj,s_parameterType);
			  t_animInfo.n_proceedTime          = 0;
			  t_animInfo.f_endCallBack          = f_endCallBack;
			  t_animInfo.x_endCallBackParameter = x_endCallBackParameter;

		--如果传入了初始值则立即生效
		if x_parameter1 ~= nil then
			changeValue_AnimSystem(t_animInfo,s_parameterType,x_parameter1);
		else
			--如果没传则将对象身上的数据作为初始数据
			t_animInfo.x_parameter1 = getValue_AnimSystem(t_animInfo,s_parameterType);
		end

		--如果有相同的则覆盖
		for k,v in pairs(t_animList) do
			if IsNil(v.go_animObj)  ==  false and go_animObj == v.go_animObj and s_parameterType == v.s_parameterType then
				t_animList[k] = t_animInfo;
				return;
			end
		end

		--将动画信息放入动画列表中，开始动画
		table.insert(t_animList,t_animInfo);
	end

	--直接停止该游戏对像上面的动画
	function AnimEnd_AnimSystem( go_animObj )

		for k,v in pairs(t_animList) do
			if IsNil(v.go_animObj)  ==  false and go_animObj == v.go_animObj then
				t_animList[k] = nil;
			end
		end
	end
--=================================================>> 外部调用函数 <<===========================================  END

--=================================================>> 核心函数 <<=============================================== START

	--取出对象的组件，避免频繁使用getComponent方法，节约开销
	function getCom_AnimSystem(go_animObj,s_parameterType)
		
		if IsNil(go_animObj) and go_animObj == nil or s_parameterType == nil then
			error("go_animObj is nil ! by AnimSystem.getCom --> s_parameterType is:"..tostring(s_parameterType));
			return;
		end
		
		if     s_parameterType == c_anchoredPosition then -- UGUI 锚点坐标
			return getComAnchoredPosition_AnimSystem( go_animObj);
		elseif s_parameterType == c_localScale       then -- 本地缩放
			return getComLocalScale_AnimSystem(       go_animObj);
		elseif s_parameterType == c_UGUI_alpha       then -- UGUI alpha 
			return getComUGUI_alpha_AnimSystem(       go_animObj);
		elseif s_parameterType == c_position         then -- 全局坐标 
			return getComPosition_AnimSystem(         go_animObj);
		elseif s_parameterType == c_particle_alpha   then -- particle_alpha
			return getComParticleAlpha_AnimSystem(    go_animObj);
		elseif s_parameterType == c_UGUI_sizeDelta   then -- UGUI_sizeDelta
			return getComSizeDelta_AnimSystem(go_animObj);
		--在这里添加对其他类型的支持
		end
	end

	--改变对象的值
	function changeValue_AnimSystem( t_animInfo,s_parameterType,x_parameter )

		if t_animInfo == nil or x_parameter == nil then
			--由于是高速调用，这里不打出异常，以免拖慢游戏运行速度
			--error("t_animInfo is nil ! by AnimSystem.changeValue --> s_parameterType is:"..tostring(s_parameterType).." x_parameter is :"..tostring(x_parameter) );
			return;
		end
		
		if     s_parameterType == c_anchoredPosition then -- UGUI 锚点坐标
			changeAnchoredPosition_AnimSystem(      t_animInfo,x_parameter);
		elseif s_parameterType == c_localScale       then -- 本地缩放
			return changeLocalScale_AnimSystem(     t_animInfo,x_parameter);
		elseif s_parameterType == c_UGUI_alpha       then -- UGUI alpha 
			return changeUGUI_alpha_AnimSystem(     t_animInfo,x_parameter);
		elseif s_parameterType == c_position         then -- 全局坐标 
			return changePosition_AnimSystem(       t_animInfo,x_parameter);
		elseif s_parameterType == c_particle_alpha   then -- particle_alpha 
			return changeParticleAlpha_AnimSystem(  t_animInfo,x_parameter);
		elseif s_parameterType == c_UGUI_sizeDelta   then -- UGUI_sizeDelta 
			return changeSizeDelta_AnimSystem(      t_animInfo,x_parameter);
		--在这里添加对其他类型的支持
		end
	end

	--取出对象的值
	function getValue_AnimSystem(t_animInfo,s_parameterType)
		
		if t_animInfo == nil or s_parameterType == nil then
			error("t_animInfo is nil ! by AnimSystem.getValue --> s_parameterType is:"..tostring(s_parameterType));
			return;
		end
		
		if     s_parameterType == c_anchoredPosition then -- UGUI 锚点坐标
			return getAnchoredPosition_AnimSystem(t_animInfo);
		elseif s_parameterType == c_localScale       then -- 本地缩放
			return getLocalScale_AnimSystem(      t_animInfo);
		elseif s_parameterType == c_UGUI_alpha       then -- UGUI alpha 
			return getUGUI_alpha_AnimSystem(      t_animInfo);
		elseif s_parameterType == c_position         then   -- 全局坐标 
			return getPosition_AnimSystem(        t_animInfo);
		elseif s_parameterType == c_particle_alpha   then   -- particle_alpha 
			return getParticleAlpha_AnimSystem(   t_animInfo);
		elseif s_parameterType == c_UGUI_sizeDelta   then   -- UGUI_sizeDelta 
			return getSizeDelta_AnimSystem(       t_animInfo);

		--在这里添加对其他类型的支持
		end
	end

	--计算对象的值
	function calcValue_AnimSystem(t_animInfo )

		if t_animInfo == nil then
			warn("t_animInfo == nil");
			return nil;
		end

		if     t_animInfo.s_parameterType == c_anchoredPosition then -- UGUI 锚点坐标
			return calculateAnchoredPosition_AnimSystem(t_animInfo);
		elseif t_animInfo.s_parameterType == c_localScale       then -- 本地缩放
			return calculateLocalScale_AnimSystem(      t_animInfo); 
		elseif t_animInfo.s_parameterType == c_UGUI_alpha       then -- UGUI alpha 
			return calculateUGUI_alpha_AnimSystem(      t_animInfo);
		elseif t_animInfo.s_parameterType == c_position         then -- 全局坐标 
			return calculatePosition_AnimSystem(        t_animInfo);
		elseif t_animInfo.s_parameterType == c_particle_alpha   then -- particle_alpha
			return calculateParticleAlpha_AnimSystem(   t_animInfo);
		elseif t_animInfo.s_parameterType == c_UGUI_sizeDelta   then -- UGUI_sizeDelta
			return calculateSizeDelta_AnimSystem(       t_animInfo);

		--在这里添加对其他类型的支持
		end
	end

	--插值算法选择函数
	function interArithmetic_AnimSystem( n_from,n_to,n_t,n_d,s_interArithmeticType)
		
		if s_interArithmeticType == c_interArithmetic_Lerp then --线性插值
			return Lerp(n_from,n_to,n_t,n_d);

		--Quad 系列
		elseif s_interArithmeticType == c_interArithmetic_outQuad then
			return outQuad(n_from,n_to,n_t,n_d);
		elseif s_interArithmeticType == c_interArithmetic_inQuad then
			return inQuad(n_from,n_to,n_t,n_d);
		elseif s_interArithmeticType == c_interArithmetic_inOutQuad then
			return inOutQuad(n_from,n_to,n_t,n_d);
		elseif s_interArithmeticType == c_interArithmetic_outInQuad then
			return outInQuad(n_from,n_to,n_t,n_d);

		--In out back系列
		elseif s_interArithmeticType == c_interArithmetic_inBack then
			return inBack(n_from,n_to,n_t,n_d);
		elseif s_interArithmeticType == c_interArithmetic_outBack then
			return outBack(n_from,n_to,n_t,n_d);
		elseif s_interArithmeticType == c_interArithmetic_inOutBack then
			return inOutBack(n_from,n_to,n_t,n_d);
		elseif s_interArithmeticType == c_interArithmetic_outInBack then
			return outInBack(n_from,n_to,n_t,n_d);

		--Cubic 系列
		elseif s_interArithmeticType == c_interArithmetic_inCubic then
			return inCubic(n_from,n_to,n_t,n_d);
		elseif s_interArithmeticType == c_interArithmetic_outCubic then
			return outCubic(n_from,n_to,n_t,n_d);
		elseif s_interArithmeticType == c_interArithmetic_inOutCubic then
			return inOutCubic(n_from,n_to,n_t,n_d);
		elseif s_interArithmeticType == c_interArithmetic_outInCubic then
			return outInCubic(n_from,n_to,n_t,n_d);


		elseif s_interArithmeticType == c_interArithmetic_customOne then --自定义算法一号
			return customOne(n_from,n_to,n_t,n_d);
		elseif s_interArithmeticType == c_interArithmetic_NewUIAnim then --新的UI进入动画
			return newUIAnim(n_from,n_to,n_t,n_d);

		--在这里添加其他算法
		else --没有找到匹配的算法默认线性插值
			return Lerp(n_from,n_to,n_t,n_d);
		end
	end
--=================================================>> 核心函数 <<===============================================  END

--=================================================>> 支持函数 <<=============================================== START

	--下面是根据不同值类型做不同表现

	----------------------------------------------->> anchoredPosition <<--------------------------------------- start
		--取出组件
		function getComAnchoredPosition_AnimSystem( go_animObj)
			if IsNil(go_animObj) then return nil end--add by sagic
			return getComponent(go_animObj,"RectTransform");
		end

		--改变anchoredPosition
		function changeAnchoredPosition_AnimSystem(t_animInfo,v3_anchoredPosition)
			
			if IsNil(t_animInfo.com_subCom) == false then
				t_animInfo.com_subCom.anchoredPosition3D = v3_anchoredPosition;
			end
		end

		--取出对象的anchoredPosition
		function getAnchoredPosition_AnimSystem(t_animInfo)
			if IsNil(t_animInfo.com_subCom) then return nil end----add by sagic

			if IsNil(t_animInfo.com_subCom) == false then
				return t_animInfo.com_subCom.anchoredPosition3D;
			end
		end

		--计算anchoredPosition
		function calculateAnchoredPosition_AnimSystem(t_animInfo)

			--这里使用插值算法
			local n_x = interArithmetic_AnimSystem(t_animInfo.x_parameter1.x,t_animInfo.x_parameter2.x,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);
			local n_y = interArithmetic_AnimSystem(t_animInfo.x_parameter1.y,t_animInfo.x_parameter2.y,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);
			local n_z = interArithmetic_AnimSystem(t_animInfo.x_parameter1.z,t_animInfo.x_parameter2.z,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);


			return Vector3.New(n_x,n_y,n_z);
		end
	----------------------------------------------->> anchoredPosition <<--------------------------------------- end

	----------------------------------------------->> localScale <<--------------------------------------------- start
		--取出组件
		function getComLocalScale_AnimSystem( go_animObj)
			if IsNil(go_animObj) then return nil end--add by sagic
			return go_animObj.transform;
		end

		--改变LocalScale
		function changeLocalScale_AnimSystem(t_animInfo,v3_LocalScale)
			if IsNil(t_animInfo.com_subCom) == false then
				t_animInfo.com_subCom.localScale = v3_LocalScale;
			end
		end

		--取出对象的LocalScale
		function getLocalScale_AnimSystem(t_animInfo)
			
			if IsNil(t_animInfo.com_subCom) == false then
				return t_animInfo.com_subCom.localScale;
			end
		end

		--计算LocalScale
		function calculateLocalScale_AnimSystem(t_animInfo)

			--这里使用插值算法
			local n_x = interArithmetic_AnimSystem(t_animInfo.x_parameter1.x,t_animInfo.x_parameter2.x,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);
			local n_y = interArithmetic_AnimSystem(t_animInfo.x_parameter1.y,t_animInfo.x_parameter2.y,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);
			local n_z = interArithmetic_AnimSystem(t_animInfo.x_parameter1.z,t_animInfo.x_parameter2.z,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);

			return Vector3.New(n_x,n_y,n_z);
		end
	----------------------------------------------->> localScale <<--------------------------------------------- end

	----------------------------------------------->> UGUI_alpha <<--------------------------------------------- start
		--取出组件
		function getComUGUI_alpha_AnimSystem( go_animObj)

			if IsNil(go_animObj) then return nil end--add by sagic

			local t_allImageCom = {};
			local t_AllChild = Global.findAllChild(go_animObj);

			--先将自身身上的Image组件放入动画列表
			-- local Image_tmp = getComponent(go_animObj,"Image");
			-- if Image_tmp ~= nil then
			-- 	table.insert(t_allImageCom , Image_tmp);
			-- end
			local Cav_render = getComponent(go_animObj,"CanvasRenderer")
			if Cav_render~=nil then
				table.insert( t_allImageCom , Cav_render )
			end

			--再将子节点的Image组件放入动画列表
			local function dump(t_result,go_childObj )
				for k,v in pairs(go_childObj) do
					if k == "mine" and getComponent(v,"Mask") == nil then

						-- local Image_tmp = getComponent(v,"Image");
						-- if Image_tmp ~= nil then
						-- 	table.insert(t_result , Image_tmp);
						-- end

						-- local Text_tmp = getComponent(v,"Text");
						-- if Text_tmp ~= nil then
						-- 	table.insert(t_result , Text_tmp);
						-- end

						--add by sagic
						local Cav_render = getComponent(v,"CanvasRenderer")
						if Cav_render~=nil then
							table.insert( t_result , Cav_render )
						end

					end

					if type(v) == "table" then
						dump(t_result,v);
					end
				end
			end

			dump(t_allImageCom,t_AllChild);

			if t_allImageCom[1] == nil then
				-- error("没有找到任何Image组件！ by AnimSystem");
			end

			-- return getComponent(go_animObj,"Image").color;
			return t_allImageCom;
		end

		--改变UGUI_alpha
		function changeUGUI_alpha_AnimSystem(t_animInfo,n_UGUI_alpha)
			if t_animInfo.com_subCom==nil then return end--add by sagic

			if t_animInfo.com_subCom[1] ~= nil  then
				for k,v in pairs(t_animInfo.com_subCom) do
					-- if type(v) == "CanvasRenderer" then

						-- warn("k: "..tostring(k));
						-- warn("v: "..tostring(v));
						-- warn(v);

						if  IsNil(v)==false then
							v:SetAlpha(n_UGUI_alpha)
						end

						-- warn("finish");
					-- else
					-- 	local Color_tmp = Color.New(v.Color.r,v.Color.g,v.Color.b,n_UGUI_alpha);
					-- 	if IsNil(v) == false then
					-- 		if v.Color ~= nil then
					-- 			v.Color = Color_tmp;
					-- 		end

					-- 	end
					-- end
				end
			end
		end

		--取出对象的UGUI_alpha
		function getUGUI_alpha_AnimSystem(t_animInfo)
			
			-- if t_animInfo.com_subCom[1] ~= nil then

			-- 	if t_animInfo.com_subCom[1].Color ~= nil then
			-- 		return t_animInfo.com_subCom[1].Color.a;
			-- 	end
			-- end

			return 1;
		end

		--计算UGUI_alpha
		function calculateUGUI_alpha_AnimSystem(t_animInfo)

			--这里使用插值算法
			local n_alpha = interArithmetic_AnimSystem(t_animInfo.x_parameter1,t_animInfo.x_parameter2,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);

			return n_alpha;
		end
	----------------------------------------------->> UGUI_alpha <<--------------------------------------------- end

	----------------------------------------------->> position <<----------------------------------------------- start
		--取出组件
		function getComPosition_AnimSystem( go_animObj)
			if IsNil(go_animObj) then return nil end--add by sagic
			return go_animObj.transform;
		end

		--改变position
		function changePosition_AnimSystem(t_animInfo,v3_position)
			
			if t_animInfo.com_subCom ~= nil then
				if IsNil(t_animInfo.com_subCom) == false then
					t_animInfo.com_subCom.position = v3_position;
				end
			end
		end

		--取出对象的position
		function getPosition_AnimSystem(t_animInfo)
			
			if t_animInfo.com_subCom ~= nil then
				return t_animInfo.com_subCom.position;
			end
		end

		--计算position
		function calculatePosition_AnimSystem(t_animInfo)

			--这里使用插值算法
			local n_x = interArithmetic_AnimSystem(t_animInfo.x_parameter1.x,t_animInfo.x_parameter2.x,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);
			local n_y = interArithmetic_AnimSystem(t_animInfo.x_parameter1.y,t_animInfo.x_parameter2.y,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);
			local n_z = interArithmetic_AnimSystem(t_animInfo.x_parameter1.z,t_animInfo.x_parameter2.z,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);

			return Vector3.New(n_x,n_y,n_z);
		end
	----------------------------------------------->> position <<----------------------------------------------- end

	----------------------------------------------->> Particle Alpha <<----------------------------------------- start
		--取出组件
		function getComParticleAlpha_AnimSystem( go_animObj)
			if IsNil(go_animObj) then return nil end--add by sagic

			local t_allImageCom = {};
			local t_AllChild = Global.findAllChild(go_animObj);

			--先将自身身上的Image组件放入动画列表
			local Particle_tmp = getComponent(go_animObj,"ParticleSystemService");
			if Particle_tmp ~= nil then
				table.insert(t_allImageCom , Particle_tmp);
			end

			--再将子节点的ParticleSystem组件放入动画列表
			local function dump(t_result,go_childObj )
				for k,v in pairs(go_childObj) do
					if k == "mine"  then

						local Particle_tmp = getComponent(v,"ParticleSystemService");
						if Particle_tmp ~= nil then
							table.insert(t_result , Particle_tmp);
						end
					end

					if type(v) == "table" then
						dump(t_result,v);
					end
				end
			end

			dump(t_allImageCom,t_AllChild);

			if t_allImageCom[1] == nil then
				-- error("没有找到任何ParticleSystem组件！ by AnimSystem");
			end

			-- print_r(t_allImageCom);
			-- return getComponent(go_animObj,"Image").color;
			return t_allImageCom;
		end

		--改变ParticleAlpha
		function changeParticleAlpha_AnimSystem(t_animInfo,n_ParticleAlpha)
			--warn("n_ParticleAlpha "..tostring(n_ParticleAlpha));
			
			if t_animInfo.com_subCom ~= nil  then

				for k,v in pairs(t_animInfo.com_subCom) do
					-- local Color_tmp = Color.New(v.startColor.r,v.startColor.g,v.startColor.b,n_ParticleAlpha);

					-- if IsNil(v) == false then
					-- 	v.startColor = Color_tmp;
					-- end
					if IsNil(v) == false then
						v:setAlpha(n_ParticleAlpha);
					end
				end
			end
		end

		--取出对象的ParticleAlpha
		function getParticleAlpha_AnimSystem(t_animInfo)

			-- if t_animInfo.com_subCom[1] ~= nil then
			-- 	if t_animInfo.com_subCom[1].startColor ~= nil then
			-- 		return t_animInfo.com_subCom[1].startColor.a;
			-- 	end
			-- end

			return 1;
		end

		--计算ParticleAlpha
		function calculateParticleAlpha_AnimSystem(t_animInfo)

			--这里使用插值算法
			local n_alpha = interArithmetic_AnimSystem(t_animInfo.x_parameter1,t_animInfo.x_parameter2,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);

			return n_alpha;
		end
	----------------------------------------------->> Particle Alpha <<----------------------------------------- end

	----------------------------------------------->> sizeDelta <<---------------------------------------------- start
		--取出组件
		function getComSizeDelta_AnimSystem( go_animObj)
			if IsNil(go_animObj) then return nil end--add by sagic
			return getComponent(go_animObj,"RectTransform");
		end

		--改变SizeDelta
		function changeSizeDelta_AnimSystem(t_animInfo,v2_SizeDelta)
			
			if IsNil(t_animInfo.com_subCom) == false then
				t_animInfo.com_subCom.sizeDelta = v2_SizeDelta;
			end
		end

		--取出对象的SizeDelta
		function getSizeDelta_AnimSystem(t_animInfo)
			
			if IsNil(t_animInfo.com_subCom) == false then
				return t_animInfo.com_subCom.sizeDelta;
			end
		end

		--计算SizeDeltaPosition
		function calculateSizeDelta_AnimSystem(t_animInfo)

			--这里使用插值算法
			local n_x = interArithmetic_AnimSystem(t_animInfo.x_parameter1.x,t_animInfo.x_parameter2.x,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);
			local n_y = interArithmetic_AnimSystem(t_animInfo.x_parameter1.y,t_animInfo.x_parameter2.y,t_animInfo.n_proceedTime,t_animInfo.n_time ,t_animInfo.s_interArithmeticType);

			return Vector2.New(n_x,n_y);
		end
	----------------------------------------------->> sizeDelta <<---------------------------------------------- end

	--下面是不同插值算法
		--form 是初始值
		--to   是终点值
		--t    是当前时间即 n_proceedTime
		--d    是总时间  即 n_time

	----------------------------------------------->> 插值算法 <<----------------------------------------------- start

		function Lerp( n_from,n_to,n_t,n_d )
			local n_td = n_t/n_d;
			return math.lerp(n_from,n_to,n_td);
		end

		function inQuad( b, c, t, d)
			c = c - b;
	 		t = t / d;
			return c * math.pow(t, 2) + b;
		end

		function outQuad(b, c, t, d)
			c = c - b;
			t = t / d;
		 	return -c * t * (t - 2) + b;
		end

		function inOutQuad(b, c, t, d)
			c = c - b;
			t = t / d * 2;
			if t < 1 then
    			return c / 2 * math.pow(t, 2) + b;
    		else
    			return -c / 2 * ((t - 1) * (t - 3) - 1) + b;
    		end
  		end

  		function outInQuad(b, c, t, d)
  			c = c - b;
			if t < d / 2 then
				return outQuad (t * 2, b, c / 2, d);
			else
			    return inQuad((t * 2) - d, b + c / 2, c / 2, d);
			end
		end

		function inBack(b, c, t, d, s)
			c = c - b;
			if not s then s = n_easeParameter end
			t = t / d;
			return c * t * t * ((s + 1) * t - s) + b;
		end

		function outBack(b, c, t, d, s)
			c = c - b;
			if not s then s = n_easeParameter end
			t = t / d - 1;
			return c * (t * t * ((s + 1) * t + s) + 1) + b;
		end

		function inOutBack(b, c, t, d, s)
			c = c - b;
			if not s then s = n_easeParameter end
			s = s * 1.525;
			t = t / d * 2;
			if t < 1 then
		    	return c / 2 * (t * t * ((s + 1) * t - s)) + b;
			else
		   		t = t - 2
		    	return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b;
			end	
		end

		function outInBack(b, c, t, d, s)
			c = c - b;
			if not s then s = n_easeParameter end
			if t < d / 2 then
		   		return outBack(t * 2, b, c / 2, d, s);
			else
		    	return inBack((t * 2) - d, b + c / 2, c / 2, d, s);
			end
		end

		function inCubic (b, c, t, d)
			c = c - b;
			t = t / d;
			return c * math.pow(t, 3) + b;
		end

		function outCubic(b, c, t, d)
			c = c - b;
			t = t / d - 1;
			return c * (math.pow(t, 3) + 1) + b;
		end

		function inOutCubic(b, c, t, d)
			c = c - b;
			t = t / d * 2;
			if t < 1 then
				return c / 2 * t * t * t + b;
			else
				t = t - 2;
				return c / 2 * (t * t * t + 2) + b;
			end
		end

		function outInCubic(b, c, t, d)
			c = c - b;
			if t < d / 2 then
				return outCubic(t * 2, b, c / 2, d);
			else
				return inCubic((t * 2) - d, b + c / 2, c / 2, d);
			end
		end

		function customOne( b, c, t, d)
			c = c - b;
			if not s then s = 0.5 end
			t = t / d - 1;
			return c * (t * t * ((s + 1) * t + s) + 1) + b;
		end

		function newUIAnim( b, c, t, d)
			c = c - b;
			if not s then s = 1 end
			t = t / d - 1;
			return c * (t * t * ((s + 1) * t + s) + 1) + b;
		end
	----------------------------------------------->> 插值算法 <<----------------------------------------------- end
--=================================================>> 支持函数 <<===============================================  END