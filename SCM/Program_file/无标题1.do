* --- 0. 配置信息 (保持你的原始代码不变) ---
global local_path "D:\研究生课程\26春\高计Ⅱ\Homework2"
global data_path "$local_path/Data_file"
global fig_path "$local_path/Fig_file"

cd $local_path

use $data_path/state_year_panel_dataset.dta , clear

global start_year 1992
global end_year 2007 
global treat_year_1 1998
global treat_year_2 2004
keep if year>=$start_year & year<=$end_year

global depend_var lfpr

global controls
global pre_end_year 1997

* 循环生成变量
forvalues y = $start_year(1)$pre_end_year  {
    local new_var_name ${depend_var}`y'
    by statefips: egen `new_var_name' = mean(cond(year == `y', $depend_var, .))
    global controls $controls `new_var_name'
}

dis "$controls"

* --- 1. 获取所有真实的 statefips 列表 ---
levelsof statefips, local(state_list)

di "检测到的州列表: `state_list'"
di "总共需要运行: `:word count `state_list'' 次"

* --- 2. 设置"数据收集器" (postfile) ---
tempname memhold
* 定义收集结构：state_id, year, y_real, y_synth
postfile `memhold' long(state_id) int(year) double(y_real) double(y_synth) ///
    using "temp_synth_results.dta", replace

	
	
dis "`state_list'" 
* --- 3. 开始循环 (遍历实际存在的 ID) ---
foreach s of local state_list {
    preserve
    
    * 运行合成控制
    quietly synth_no_rounding lfpr $controls, ///
        trunit(`s') trperiod($treat_year_1 ) 
    
    * --- 提取结果 ---
    if _rc == 0 {
        mat Y_tr = e(Y_treated)
        mat Y_sy = e(Y_synthetic)
        
        local rows = rowsof(Y_tr)
        
        * --- 【关键修正】正确计算年份 ---
        * synth 返回的矩阵行号 r 从 1 开始
        * 第 1 行对应 start_year (1992)
        * 第 2 行对应 start_year + 1 (1993)
        * 所以：真实年份 = start_year + (r - 1)
        forvalues r = 1/`rows' {
            local current_year = $start_year + `r' - 1  // 修正：使用 $start_year 而非不存在的 `start_y'
            
            * 写入数据
            post `memhold' (`s') (`current_year') (Y_tr[`r',1]) (Y_sy[`r',1])
        }
    }
    else {
        di as error "州 `s' 合成控制失败，跳过。"
    }
    
    restore
}

* 关闭收集器
postclose `memhold'
di "计算完成，正在绘图..."

* -