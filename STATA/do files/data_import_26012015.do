global myDir "C:\Users\thomas.goetschi\Google Drive\PASTA\WP3\WORK\Analysis\STATA"

clear
* Create question file (listing all variables; ev.  get export of question table from Arnout)
insheet using "$myDir\raw platform data\_Antwerpen\_Antwerpen.csv", delim(";") clear
local N=_N
drop in 1/`N'
save "$myDir\raw platform data\allvars.dta", replace

* Append city files

global citylist Antwerpen Barcelona Zurich

use "$myDir\raw platform data\allvars.dta", clear
save "$myDir\raw platform data\alldata.dta", replace   /*Make sure variable formats are correct here, i.e. string, byte, etc.*/

foreach city in $citylist {
	insheet using "$myDir\raw platform data\_`city'\_`city'.csv", delim(";") clear
	save "$myDir\raw platform data\_`city'\_`city'.dta", replace
	use "$myDir\raw platform data\alldata.dta", clear
	append using "$myDir\raw platform data\_`city'\_`city'.dta", force
	save "$myDir\raw platform data\alldata.dta", replace
	}
	
* Add stageid (currently missing. But ideally fixed on VITO end)
	** currently not possible to chronologically id stages

use "$myDir\raw platform data\alldata.dta", clear	
* Resort data (more natural for visual inspection
sort cityname userid questionnaireid questionid subquestion tripid, stable
order cityname userid questionnaireid questionid tripid subquestion 

**********************************************************************************************
* Basic descriptives (mainly for TH conference abstract)
		
		gen one=1
		gen female=1 if usersex=="F"
		replace female=0 if usersex=="M"
		collapse  female (sum) N_rows=one , by(cityname type questionnaireid userid tripid)
		save collapsed_data, replace
		* Reported trips per user
		collapse  (count) N_trp=tripid , by(cityname type questionnaireid userid)
		egen mean_trips=mean(N_trp)
		egen sum_trips=sum(N_trp)
		save trips_per_user, replace
		* Response rows per questionnaire
		use collapsed_data, clear
		collapse  female (sum) N_rows=N_rows  , by(cityname type questionnaireid userid)
		egen mean_rows=mean(N_rows), by(questionnaireid)
		gen incomplete_Qs=0
		replace incomplete_Qs=1 if N_rows<0.8*mean_rows
		collapse (mean) female (count) N_usr=userid (mean) mean_rows=N_rows prop_incomplete=incomplete_Qs, by(cityname type questionnaireid)
		gsort cityname -N_usr /*to simulate chronologic order - later this should be fixed with key for Qid*/
		format %4.0f mean_rows 
		format %3.2f prop
		gen drop_out=N_usr[_n]/N_usr[_n-1]
		save Q_ns_burden_incomplete, replace
		* Gender
		use collapsed_data, clear
		collapse  female
		* Mode frequency (q75)
		use "$myDir\raw platform data\alldata.dta", clear
		keep if questionid==75
		encode subquestion , gen(mode) label(modelab)
		encode answer , gen(freq) label(freqlab)
		proportion freq if mode==1
		proportion freq if mode==2
		** Total sample size

XX************ notes, to do's

PS could you look into the power calculations again and comment on what can be done already with the present sample.



sort userid questionnaireid questionid subquestion tripid
