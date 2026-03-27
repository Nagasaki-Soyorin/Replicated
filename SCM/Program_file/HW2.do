global local_path "D:\研究生课程\26春\高计Ⅱ\Homework2"
global data_path "$local_path/Data_file"
global fig_path "$local_path/Fig_file"

cd $local_path


use $data_path/state_year_panel_dataset.dta , clear


* ==================================================================
*                            给出配置信息
* ==================================================================

global start_year 1992
global end_year 2007 
global treat_year_1 1998
global treat_year_2 2004
keep if year>=$start_year & year<=$end_year

global depend_var lfpr


global controls //$depend_var
global pre_end_year 1997 //方便循环一下
// forvalues i=$start_year(1)$pre_end_year  {
// global controls $controls ${dep}(`i')
// }

* 循环生成变量
forvalues y = $start_year(1)$pre_end_year {
    * 1. 定义新变量名，例如 lfpr1992
    local new_var_name ${depend_var}`y'
    
    * 2. 【关键步骤】生成新变量
    * 逻辑：按州分组，提取该州在年份 `y' 时的 $depend_var 值，并广播到该州所有行
    by statefips: egen `new_var_name' = mean(cond(year == `y', $depend_var, .))
    
    * 3. 将新变量名添加到全局宏列表中
    global controls $controls `new_var_name'
}

* 查看结果

describe $controls
display "生成的控制变量列表: $controls"





* ==================================================================
*                            Figure 2
* ==================================================================
cap program drop synth_no_rounding
synth_no_rounding lfpr $controls , trunit(48) trperiod($treat_year_1) figure saving("$fig_path/Fig_1") replace


* ==================================================================
*                            Figure 4
* ==================================================================

preserve

keep if energystate

cap program drop synth_no_rounding
synth_no_rounding lfpr $controls , trunit(48) trperiod($treat_year_1) figure saving("$fig_path/Fig_energystate") keep( "$data_path/Fig_energystate.dta")replace


restore


preserve
keep if noDminwage
cap program drop synth_no_rounding
synth_no_rounding lfpr $controls , trunit(48) trperiod($treat_year_1) figure saving("$fig_path/Fig_noDminwage") keep( "$data_path/Fig_noDminwage.dta")replace

restore


preserve
keep if DwelfareQ34

cap program drop synth_no_rounding
synth_no_rounding lfpr $controls , trunit(48) trperiod($treat_year_1) figure saving("$fig_path/Fig_DwelfareQ34") keep( "$data_path/Fig_DwelfareQ34.dta")replace

restore


preserve
keep if !stateitc

cap program drop synth_no_rounding
synth_no_rounding lfpr $controls , trunit(48) trperiod($treat_year_1) figure saving("$fig_path/Fig_stateitc") keep( "$data_path/Fig_stateitc.dta")replace


restore



* 绘图部分
// 见python
