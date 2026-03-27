**NOTE THAT THE ORIGINAL SYNTH PROGRAM ROUNDS WEIGHTS AFTER ESTIMATING THOSE WEIGHTS
**TO AVOID ROUNDING JUST USE A VERSION WHERE ROUNDING IS COMMENTED OUT
**run the synthprogram without rounding of weights
qui do programs\synth_no_rounding.ado

use "data\state_year_panel_dataset", clear
keep if year>=1992 & year<=2007

forv kk=1/4 {

preserve

global start=1992
global end=2007
keep if year>=$start & year<=$end
if `kk'==1 {
keep if energystate
local title="Energy States"
}
else if `kk'==2 {
keep if noDminwage
local title="No Minimum Wage Change"
}
else if `kk'==3 {
keep if DwelfareQ34
local title="Similar Welfare Reform"
}
else if `kk'==4 {
keep if !stateitc
local title="No State EITC Change"
}

global t0=1997
global t1=$t0+1

global dep lfpr

global controls
forv i=$t0(-1)$start {
global controls $controls  ${dep}(`i')
}
di "$controls "

global controls $controls  

**Model 1: constrained model
synth $dep $controls, trunit(48) trperiod($t1) unitnames(stateusps) keep(synth.dta) replace fig 

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
label var effect "`title'"
di `kk'

**for overlaying differnt lines on one graph
if `kk'==1 {
line effect time, name(effect, replace) sort xlab($start(3)$end, labsize(small)) ylab(-3(1)2, labsize(small)) xline($t0 2003, lp(dash)) yline(0, lp(dash)) xtitle("") ytitle("Gap in `:variable label $dep' (TX minus Synthetic TX)", size(vsmall)) legend(size(vsmall)) lp(solid)
}
else if `kk'==2 {
graph di effect
addplot effect: line effect time, sort xlab($start(3)$end, labsize(small)) ylab(-3(1)2, labsize(small)) xline($t0 2003, lp(dash)) yline(0, lp(dash)) xtitle("") ytitle("Gap in `:variable label $dep' (TX minus Synthetic TX)", size(vsmall)) legend(size(vsmall)) lp(dash) 
}
else if `kk'==3 {
graph di effect
addplot effect: line effect time, sort xlab($start(3)$end, labsize(small)) ylab(-3(1)2, labsize(small)) xline($t0 2003, lp(dash)) yline(0, lp(dash)) xtitle("") ytitle("Gap in `:variable label $dep' (TX minus Synthetic TX)", size(vsmall)) legend(size(vsmall)) lp(longdash) 
}
else if `kk'==4 {
graph di effect
addplot effect: line effect time, sort xlab($start(3)$end, labsize(small)) ylab(-3(1)2, labsize(small)) xline($t0 2003, lp(dash)) yline(0, lp(dash)) xtitle("") ytitle("Gap in `:variable label $dep' (TX minus Synthetic TX)", size(vsmall)) legend(size(vsmall)) lp(shortdash)
}
drop Y_treated Y_synthetic effect time


restore

}

gr di effect
addplot:, title("Robustness of SCM Estimates of the Effect on `:variable label $dep' to Alternative Donor Pools", size(small)) xlab($start(3)$end, labsize(small)) ylab(-3(1)2, labsize(small)) 
graph save "$resultsdir\Figure 3.gph", replace