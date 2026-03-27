// Derived from https://github.com/gslab-econ/template/blob/master/config/config_stata.do
// with minor corrections

clear all
set more off

****************************************************************************************************************************
****************************************************************************************************************************
****************************************************************************************************************************
**IMPORTANT: UNCOMMENT THE FOLLOWING CODE AND INSTALL THE FOLLOWING PACKAGES IF NOT ALREADY INSTALLED

program main
    * *** Add required packages from SSC to this list ***
    local ssc_packages "synth estadd estout _eststo eststo esttab grc1leg lgraph _gwtmean labutil"
    * *** Add required packages from SSC to this list ***

    if !missing("`ssc_packages'") {
        foreach pkg in `ssc_packages' {
        * install using ssc, but avoid re-installing if already present
            capture which `pkg'
            if _rc == 111 {                 
               dis "Installing `pkg'"
               quietly ssc install `pkg', replace
               }
        }
    }

* Install packages using net, but avoid re-installing if already present
**uncomment the following to install synth_runner. Alternatovely, download synth_runner from https://raw.github.com/bquistorff/synth_runner/master/ and place it in C:\ado\plus
    capture which synth_runner 
       if _rc == 111 {
        quietly cap ado uninstall synth_runner
        quietly net install synth_runner, from("https://raw.github.com/bquistorff/synth_runner/master/") replace
       }
***NOTE: svmat2 is needed from dm79, but installation of dm79 commented out because the download link may not work, so these ado files are provided in "replicate\programs\stata_ado_files"*/
/*
	capture which dm79 
       if _rc == 111 {
	    quietly cap ado uninstall dm79
        quietly net install dm79, from ("http://www.stata.com/stb/stb56/") replace
*/
**uncomment the following to install labutil. Alternatovely, download labutil from http://fmwww.bc.edu/RePEc/bocode/l and place it in C:\ado\plus
/*
	capture which labutil 
       if _rc == 111 {
        quietly cap ado uninstall labutil
        quietly net install labutil, from ("http://fmwww.bc.edu/RePEc/bocode/l") replace
       }
*/
    **Install complicated packages : moremata (which cannot be tested for with which)
    capture confirm file $adobase/plus/m/moremata.hlp
        if _rc != 0 {
        cap ado uninstall moremata
        ssc install moremata
        }

end

**Run the program by uncommenting it if any of the above packages need to be installed
main


/*==============================================================================================*/
/* after installing all packages, it may be necessary to issue the mata mlib index command */
/* This should always be the LAST command after installing all packages                    */
**uncomment it if needed after installing all packges
mata: mata mlib index
