* --- 0. 配置信息 ---
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
global pre_end_year 1997

* --- 【关键】先生成所有控制变量并保存 ---
global controls
forvalues y = $start_year(1)$pre_end_year  {
    local new_var_name ${depend_var}`y'
    by statefips: egen `new_var_name' = mean(cond(year == `y', $depend_var, .))
    global controls $controls `new_var_name'
}

* 生成 unit_id
gen unit_id = .
levelsof statefips, local(state_list)
local i = 0
foreach s of local state_list {
    local ++i
    replace unit_id = `i' if statefips == `s'
}

* 【关键】保存带有控制变量的完整数据
save "$fig_path/temp_full_data.dta", replace

dis "控制变量: $controls"
di "州列表: `state_list'"

* --- 设置收集器 ---
tempname memhold
postfile `memhold' long(state_id) int(year) double(y_real) double(y_synth) ///
    using temp_synth_results.dta, replace

* --- 循环处理 ---
foreach s of local state_list {
    
    * 重新加载完整数据（包含控制变量）
    use "$fig_path/temp_full_data.dta", clear
    
    * 获取 unit_id
    quietly sum unit_id if statefips == `s'
    local u = r(mean)
    
    di "处理 Statefips `s' (Unit `u')..."
    
    * 运行合成控制
    capture quietly synth_no_rounding lfpr $controls, ///
        trunit(`s') trperiod($treat_year_1 )
    
    if _rc != 0 {
        di "  synth_no_rounding 失败，尝试 synth..."
        capture quietly synth_no_rounding lfpr $controls, ///
        trunit(`s') trperiod($treat_year_1 )
    }
    
    * 提取结果
    if _rc == 0 {
        mat Y_tr = e(Y_treated)
        mat Y_sy = e(Y_synthetic)
        local rows = rowsof(Y_tr)
        
        forvalues r = 1/`rows' {
            local current_year = $start_year + `r' - 1
            post `memhold' (`s') (`current_year') (Y_tr[`r',1]) (Y_sy[`r',1])
        }
        di "  -> 成功，`rows' 年"
    }
    else {
        di as error "  -> 失败，错误码: " _rc
    }
}

postclose `memhold'

* --- 清理和保存结果 ---
// erase "temp_full_data.dta"
use temp_synth_results.dta, clear
gen gap = y_real - y_synth
save temp_synth_results.dta, replace
list in 1/20