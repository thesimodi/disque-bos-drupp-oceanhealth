data_prep:
	quarto render 4_Code/01_Prep_Decision_Data.qmd
	quarto render 4_Code/02_Prep_Quality_Controls.qmd
	quarto render 4_Code/03_Prep_Survey_Data.qmd
	quarto render 4_Code/04_GARP_Test.qmd
# 	rm 4_Code/01_Prep_Decision_Data.html \
# 		4_Code/02_Prep_Quality_Controls.html \
# 		4_Code/03_Prep_Survey_Data.html \
# 		4_Code/04_GARP_Test.html

matlab_estimation:
# 	# 1. Make sure you have a valid license / are in the VPN for Matlab
# 	# 2. Ensure to have matlab in $PATH
# 	#		 export PATH="/Applications/MATLAB_R2024a.app/bin:$PATH"
	matlab -batch "run 4_Code/Matlab_OHI/A_CES_Estimation_OHI.m; exit;"

produce_figures:
	quarto render 4_Code/05_Sample_Selection.qmd
	quarto render 4_Code/06_Figures.qmd
# 	rm 4_Code/06_Figures.html