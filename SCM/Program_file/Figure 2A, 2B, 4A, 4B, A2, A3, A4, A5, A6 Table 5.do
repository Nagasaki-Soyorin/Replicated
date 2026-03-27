set matsize 10000

use "data\state_year_panel_dataset.dta", clear

char year[omit] 1997
char statefips[omit] 1
char division[omit] 1
char groupstateusps[omit] 1

xi i.statefips i.year i.year*texas i.statefips*t i.statefips*t2 i.groupstateusps*t i.division*i.year i.region*i.year


global expl1 lnrahem sttaxr lnhpifhfa
global expl2 age female married child white collegeplus


label var lfpr "LFPR"

**NOTE THAT THE ORIGINAL SYNTH PROGRAM ROUNDS WEIGHTS AFTER ESTIMATING THOSE WEIGHTS
**TO AVOID ROUNDING JUST USE A VERSION WHERE ROUNDING IS COMMENTED OUT
**run the synthprogram without rounding of weights
qui do programs\synth_no_rounding.ado

**RESIDULIZE HOUSE PRICES FROM LFPR AND REPLACE DEP VAR WITH RESIDUALIZED LFPR
reg lfpr D1lnhpifhfa
cap drop Rlfpr
predict Rlfpr, resid

**MAIN ESTIMATES
****
cap program drop run_synth
program run_synth 
synth $dep $controls, trunit(48) trperiod($t1) unitnames(stateusps) keep(synth.dta) replace fig

graph rename synth_figure, replace

mat X_balance=e(X_balance)

mat W_weights=e(W_weights)
cap drop _Co_Number
cap drop _W_Weight
cap drop temp
svmat2 W_weights, names(col) rnames(temp) full
cap drop synthweight
rename _W_Weight synthweight
cap drop rsynthweight
egen rsynthweight=rank(synthweight) if synthweight <.

graph bar synthweight if synthweight>0.001 & !texas, over(temp, sort(synthweight) descending label(labsize(tiny))) title("Synthetic Weights", size(small)) ytitle("") ylab(,labsize(small)) name(synth_weights, replace)

drop _Co_Number synthweight temp rsynthweight

**graph effects
mat Y_synthetic=e(Y_synthetic)
cap drop Y_synthetic
cap drop time
svmat2 Y_synthetic, names("Y_synthetic") rnames(time) full
mat Y_treated=e(Y_treated)
cap drop Y_treated
cap drop time
svmat2 Y_treated, names("Y_treated") rnames(time) full
cap drop effect
gen effect=Y_treated-Y_synthetic
destring time, replace
sum effect if year>=$t1
cap drop meaneffect
gen meaneffect=r(mean)
label var meaneffect "Post-HEL Mean Effect"
label var effect "Treatment Effect"

drop Y_treated Y_synthetic effect time

foreach x in lead ${dep}_synth effect pre_rmspe post_rmspe {
cap drop `x'
}

synth_runner $dep $controls, trunit(48) trperiod($t1) unitnames(stateusps) gen_vars 

mat b=e(b)
mat pvals=e(pvals)
mat pvals_std=e(pvals_std)

**Post-Treatment Mean Effect
sum effect if year>=$t1 & texas
estadd scal posteffect=r(mean), replace
**Post-Treatment P-value
**use e(pval_joint_post_std)
**Pre-Treatment Mean Effect
sum effect if year<$t1 & texas
estadd scal preeffect=r(mean), replace
**Pre-Treatment P-value
**e(avg_pre_rmspe_p)
**Pre-Treatment RMSPE: Texas
sum pre_rmspe if year<$t1 & texas
estadd scal prermse_treated=r(mean), replace
**Pre-Treatment RMSPE: Controls
sum pre_rmspe if year<$t1 & !texas
estadd scal prermse_controls=r(mean), replace

local names
forv i=$t1/$end {
local names `names' `i'
}
mat colnames b=`names'
mat colnames pvals=`names'
mat colnames pvals_std=`names'

erepost b=b, rename
estadd mat pvals=pvals, replace
estadd mat pvals_std=pvals_std, replace

cap drop test
gen test=post_rmspe/pre_rmspe
label var test "Post-Treatment/Pre-Treatment RMSPE" 
**label var pre_rmspe "Pre-Treatment RMSPE"
**graph bar pre_rmspe, over(stateusps, sort(pre_rmspe) label(labsize(tiny))) 
sum test if texas
local rtest=r(mean)
levelsof test, local(ltest) clean
local pos: list posof "`rtest'" in ltest
di `pos'
cap drop septest0 
cap drop septest1
separate test, by(texas) gen(septest)

graph bar septest0 septest1, over(stateusps, sort(test) label(labsize(tiny))) title("Post-Treatment/Pre-Treatment RMSPE", size(small)) ylab(,labsize(vsmall)) legend(off) nofill name(synth_post_by_pre_rmspe, replace)

**Placebo Charts by states

sum pre_rmspe, det
local rmspep95=r(p95)
qui tab statefips if pre_rmspe<=`rmspep95'
di r(r)

levelsof statefips if pre_rmspe<=`rmspep95', local(states) clean
di "`states'"
local pos: list posof "48" in states
di `pos'
xtline effect if pre_rmspe<=`rmspep95', overlay plot`pos'(lw(thick) lc(black)) legend(off) xline($t0 2003, lp(dash)) title("All States*", size(small)) ytitle("Gap in `:variable label $dep'", size(small)) ylab(,labsize(small)) xtitle("") xlab($start(3)$end,labsize(small))  name(placebo_all, replace)

end

**FIGURES 2A, 2B, APPENDIX FIGURES A2, A3 AND TABLE 5
**clear estimates before estimting main models
estimates clear

preserve

global start=1992
global end=2007
keep if year>=$start & year<=$end

global t0=1997
global t1=$t0+1

global dep lfpr
global controls

**SYNTHETIC CONTROL
**Model (1)
**constrained regression model (Doudchenko and Imbens, 2017)

forv i=$t0(-1)$start {
global controls $controls ${dep}(`i')
}
di "$controls"

run_synth

**save estimates for tabulating later (Model 1: Constrained Model)
eststo:

graph di synth_figure
graph play "programs\stata_ado_files\grec\delete_xline.grec"
addplot:, title("`:variable label $dep' in Texas vs. Synthetic Texas Before and After Home equity Access", size(small)) xline($t0 2003, lp(dash)) xlab($start(1)$end, labsize(small)) xtitle("") ytitle("")
graph save "$resultsdir\Figure 2A.gph", replace

graph di synth_weights
**addplot:, title("Estimated Weights for Synthetic Texas", size(small)) 
gr_edit .title.text = {}
gr_edit .title.text.Arrpush "Estimated Weights for Synthetic Texas"
graph save "$resultsdir\Figure A2.gph", replace

graph di synth_post_by_pre_rmspe
**addplot:, title("Post-Treatment/Pre-Treatment RMSPE", size(small)) 
gr_edit .title.text = {}
gr_edit .title.text.Arrpush "Post-Treatment/Pre-Treatment RMSPE"
graph save "$resultsdir\Figure A3.gph", replace

**save the mian placebo graph with all states
gr di placebo_all
addplot:, title("Synthetic Control Estimates of the Effect of Home Equity Access on `:variable label $dep' in Texas vs. Placebo States", size(small)) xline($t0 2003, lp(dash)) xlab($start(3)$end, labsize(small)) xtitle("") ytitle("")
graph save "$resultsdir\Figure 2B.gph", replace

putexcel set "$resultsdir\house_price_effect.xlsx", sheet("sheet1", replace) replace
putexcel A1="year"
putexcel B1="effect_treated_original"
putexcel C1="effect_synthetic_original"
putexcel A2=matrix(Y_treated), rownames
putexcel C2=matrix(Y_synthetic)

**save effect and placebo data for later use
keep statefips year effect
egen groupstate=group(statefips) if statefips!=48
replace groupstate=groupstate+1
replace groupstate=1 if statefips==48
drop statefips
order groupstate year
sort groupstate year
reshape wide effect, i(year) j(groupstate)
rename effect1 synth
rename effect* synthplacebo*
save "$resultsdir\synthoutput.dta", replace

restore

preserve

global start=1992
global end=2007
keep if year>=$start & year<=$end

global t0=1997
global t1=$t0+1

global dep lfpr
global controls

**Model (2)
**Synthetic Control Model with Three Pre-Treatment Lags and Key Covariates
global controls
**for intermittent pre-treatment lags
forv i=$t0(-2)$start {
**for three most recent pre-treatment lags
**local j=$t0-2
**forv i=$t0(-1)`j' {
global controls $controls ${dep}(`i')
}
global controls $controls $expl1
di "$controls"

run_synth
**save estimates for tabulating later (Model 2: Model with Covariates)
eststo:

restore

preserve

**Model (4)
**energy states
keep if energystate==1

global start=1992
global end=2007
keep if year>=$start & year<=$end

global t0=1997
global t1=$t0+1

global dep lfpr
global controls

forv i=$t0(-1)$start {
global controls $controls ${dep}(`i')
}
di "$controls"

run_synth
**save estimates for tabulating later (Model 3: Donor Pool Energy States)
eststo:

**save effect and placebo data for later use
keep statefips year effect
egen groupstate=group(statefips) if statefips!=48
replace groupstate=groupstate+1
replace groupstate=1 if statefips==48
drop statefips
order groupstate year
sort groupstate year
reshape wide effect, i(year) j(groupstate)
rename effect1 synth
rename effect* synthplacebo*
save "$resultsdir\synthoutput_energy_states.dta", replace

restore

**make a combined table of 3 SCM models
esttab using "$resultsdir\Table 5.rtf", replace cells(b(fmt(3)) /*pvals(par(\{ \}))*/ pvals_std(par([ ]))) scalar("posteffect Post-Treatment Mean Effect" "pval_joint_post_std Post-Treatment P-value" "preeffect Pre-Treatment Mean Effect" "avg_pre_rmspe_p Pre-Treatment P-value" "prermse_treated Pre-Treatment RMSPE: Texas" "prermse_controls Pre-Treatment RMSPE: Controls") mtitle("All Pre-Treatment Lags" "Model with Covariates" "All Pre-Treatment Lags: Energy States") nonumbers noobs gap addnotes("Standardized P-values reported in square brackets. Pre-treatment period: $start-$t0; Post-treatment period: $t1-2007; Treated group: Texas; Control Group: 49 remaining states.") align(ctr) varwidth(30) modelwidth(20)


**FIGURES 4A, 4B, APPENDIX FIGURES A5, A6

**Model (5)
**HELOC Effect
**clear estimates
estimates clear

preserve

global start=1998
global end=2007
keep if year>=$start & year<=$end

global t0=2003
global t1=$t0+1

global controls

forv i=$t0(-1)$start {
global controls $controls ${dep}(`i')
}
di "$controls"

run_synth

graph di synth_figure
graph play "programs\stata_ado_files\grec\delete_xline.grec"
addplot:, title("`:variable label $dep' in Texas vs. Synthetic Texas Before and After Home equity Access", size(small)) xline($t0 2003, lp(dash)) xlab($start(1)$end, labsize(small)) xtitle("") ytitle("")
graph save "$resultsdir\Figure 4A.gph", replace

graph di synth_weights
**addplot:, title("Estimated Weights for Synthetic Texas", size(small)) 
gr_edit .title.text = {}
gr_edit .title.text.Arrpush "Estimated Weights for Synthetic Texas"
graph save "$resultsdir\Figure A5.gph", replace

graph di synth_post_by_pre_rmspe
**addplot:, title("Post-Treatment/Pre-Treatment RMSPE", size(small)) 
gr_edit .title.text = {}
gr_edit .title.text.Arrpush "Post-Treatment/Pre-Treatment RMSPE"
graph save "$resultsdir\Figure A6.gph", replace

**save the mian placebo graph with all states
gr di placebo_all
addplot:, title("Synthetic Control Estimates of the Effect of Home Equity Access on `:variable label $dep' in Texas vs. Placebo States", size(small)) xline($t0 2003, lp(dash)) xlab($start(3)$end, labsize(small)) xtitle("") ytitle("")
graph save "$resultsdir\Figure 4B.gph", replace

restore

**MAIN MODELS CONTROLLING FOR HOUSE PRICE

**clear estimates before estimting main models
estimates clear

preserve

global start=1992
global end=2007
keep if year>=$start & year<=$end

global t0=1997
global t1=$t0+1

global dep Rlfpr
global controls

**SYNTHETIC CONTROL
**Model (2)
**constrained regression model (Doudchenko and Imbens, 2017)

forv i=$t0(-1)$start {
global controls $controls ${dep}(`i')
}
di "$controls"

run_synth
**save estimates for tabulating later (Model 1: Constrained Model)
eststo:

putexcel D1="effect_treated_house_price"
putexcel E1="effect_synthetic_house_price"
putexcel D2=matrix(Y_treated)
putexcel E2=matrix(Y_synthetic)

restore

**FIGURE A4

preserve

import excel "$resultsdir\house_price_effect.xlsx", sheet("sheet1") firstrow clear

destring year, replace
rename effect* pred*

global start=1992
global end=2007
keep if year>=$start & year<=$end

global t0=1997
global t1=$t0+1

gen effect_original=pred_treated_original-pred_synthetic_original
gen effect_house_price=pred_treated_house_price-pred_synthetic_house_price

label var effect_original "Not Controlling for House Price"
label var effect_house_price "Controlling for House Price"

line effect_original effect_house_price year, sort lp(solid dash) legend(size(small)) xlab($start(1)$end, labsize(small)) ylab(-3(1)2, labsize(small)) xline($t0 2003, lp(dash)) yline(0, lp(dash)) xtitle("") ytitle("Gap in LFPR (TX minus Synthetic TX)", size(small)) title("Synthetic Control Estimates of the Effect of Home Equity Access on LFPR", size(small))  saving("$resultsdir\Figure A4.gph", replace)

restore