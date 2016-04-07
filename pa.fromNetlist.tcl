
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name vga -dir "Z:/Documents/ISE/Lab3 - VGA/vga/planAhead_run_1" -part xc3s100ecp132-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "Z:/Documents/ISE/Lab3 - VGA/vga/top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {Z:/Documents/ISE/Lab3 - VGA/vga} }
set_param project.pinAheadLayout  yes
set_property target_constrs_file "top.ucf" [current_fileset -constrset]
add_files [list {top.ucf}] -fileset [get_property constrset [current_run]]
link_design
