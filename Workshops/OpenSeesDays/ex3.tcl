# EXAMPLE 1 - Single DOF Problem

puts "usage: OpenSees ex3.tcl Tn dt T response gamma beta"
if {$argc < 6} {
    set Tn 1.0
    set dT 0.01
    set responseQuantity disp
    set T 10.0
    set gamma 0.5
    set beta 0.25
} else {
    set Tn [lindex $argv 0]
    set dT [lindex $argv 1]
    set T  [lindex $argv 2]
    set responseQuantity [lindex $argv 3]
    set gamma [lindex $argv 4]
    set beta [lindex $argv 5]
}

puts "Period: $Tn dT: $dT dT/Tn: [expr $dT/$Tn] T: $T"

#set some constants
set g 386.4
set PI [expr 2.0 * asin(1.0)]
set K 4.0

puts [expr 1.0/$PI]

# set some variables
#derived quantaties

set factorDt [expr $dT/$Tn]
set Wn [expr 2.0 * $PI / $Tn]
set W [expr 2.0 * $PI / $T]

set M [expr $K / ($Wn * $Wn)]

set numTn  10
set maxT [expr $numTn*$Tn];

set mFile [open plot1.m w]
puts $mFile "close all;"

if {$responseQuantity == "disp"} {
    set plotIt "plot(a,sin($W*a),'r',a,1/(1-($W/$Wn)*($W/$Wn))*(sin($W*a)-($W/$Wn)*sin($Wn*a)),'x-r'"
} elseif {$responseQuantity == "vel"} {
    set plotIt "plot(a,-$Wn*sin($Wn*a),'x-r'"
} elseif {$responseQuantity == "accel"} {
    set plotIt "plot(a,-$Wn*$Wn*cos($Wn*a),'x-r'"    
}
set legendIt "legend(\"SteadyState\",\"Theoretical\""
set count 1

set intTypes  {NewmarkGamma HHTpt9 HHTpt6 TRBDF2 NewmarkAverage}

foreach intType $intTypes {    

puts $intType

    # create the model
    wipe
    model basic -ndm 1 -ndf 1
    
    node  1       0.0
    node  2       1.0  -mass $M
    
    fix 1 1
    uniaxialMaterial Elastic  1 $K 0.0
#    uniaxialMaterial Elastic  2 0.0 $c
    uniaxialMaterial  Parallel 3 1 
    
    element truss 1 1 2 1.0 1
    
    set nPts 0;
    set factor $g
    
    timeSeries Trig 1 0.0 [expr 1000*$T] $T 
    pattern Plain 1 1 {
	load 2 [expr $K]
    }

    # create the analysis
    constraints Plain
    test NormUnbalance 1.0e-12  6 0
    algorithm Newton

    if {$intType == "NewmarkGamma"} {
	puts "integrator Newmark $gamma $beta"
	integrator Newmark $gamma $beta
	set color "0"
    } elseif {$intType == "NewmarkAverage"} {
	integrator Newmark 0.5 0.25
	set color "1"
    } elseif {$intType == "HHTpt9"} {
	set color "2"
	integrator HHT 0.9
     } elseif {$intType == "HHTpt6"} {
	integrator HHT 0.6
	 set color "3"
    } elseif {$intType == "NewmarkLinear"} {
	integrator Newmark 0.5 [expr 1.0/6.0]
	set color "4"
    } elseif {$intType == "TRBDF2"} {
	set color "5"
	integrator TRBDF2
    }

    system ProfileSPD
    numberer RCM
    analysis Transient
    
    set t 0.0
    set ok 0.0
    
    recorder Node -file node$intType.out -time -node 2 -dof 1 $responseQuantity
    record

    while {$ok == 0 && $t < $maxT} {
	set ok [analyze 1 $dT]
	if {$ok != 0} {
	    test NormDispIncr 1.0e-12  100 0
	    algorithm ModifiedNewton -initial
	    set ok [analyze 1 .01]
	    test NormDispIncr 1.0e-12  10 
	    algorithm Newton
	}
	
	set t [getTime]
    }
    puts $mFile "load node$intType.out"
    if {$count == 1} {
	puts $mFile "a=node$intType\(:,1\);"
    } 
    set plotIt "$plotIt,node$intType\(:,1\),node$intType\(:,2\),'$color'"
    if {$intType == "NewmarkGamma"} {
	set legendIt "$legendIt,\"Newmark$gamma\""
    } else {
	set legendIt "$legendIt,\"$intType\""
    }

    incr count
}

puts "HELLO"
set plotIt "$plotIt)"
set legendIt "$legendIt)"
puts $mFile $plotIt
puts $mFile "xlabel(\"Time\");"
puts $mFile "ylabel(\"$responseQuantity\");"
puts $mFile "title(\"Harmonic Vibration Response for dt/Tn = $factorDt W/Wn = [expr $W/$Wn]\");"
puts $mFile $legendIt

set numTn  100
set maxT [expr $numTn*$Tn];

foreach intType $intTypes {    

    # create the model
    wipe
    model basic -ndm 1 -ndf 1
    
    node  1       0.0
    node  2       1.0  -mass $M
    
    fix 1 1
    uniaxialMaterial Elastic  1 $K 0.0
#    uniaxialMaterial Elastic  2 0.0 $c
    uniaxialMaterial  Parallel 3 1 
    
    element truss 1 1 2 1.0 1
    
    set nPts 0;
    set factor $g
    
    timeSeries Trig 1 0.0 [expr 1000*$T] $T 
    pattern Plain 1 1 {
	load 2 [expr $K]
    }
    
    # create the analysis
    constraints Plain
    test NormUnbalance 1.0e-12  6 0
    algorithm Newton

    if {$intType == "NewmarkGamma"} {
	puts "integrator Newmark $gamma [expr ($gamma+0.5)*($gamma+0.5)/4]"
	integrator Newmark $gamma [expr ($gamma+0.5)*($gamma+0.5)/4]
	set color "0"
    } elseif {$intType == "NewmarkLinear"} {
	integrator Newmark 0.5 [expr 1.0/6.0]
	set color "+-r"
    } elseif {$intType == "NewmarkAverage"} {
	integrator Newmark 0.5 0.25
	set color "+-b"
    } elseif {$intType == "HHTpt9"} {
	set color "2"
	integrator HHT 0.9
     } elseif {$intType == "HHTpt6"} {
	integrator HHT 0.6
	 set color "3"
    } elseif {$intType == "GeneralizedAlpha1pt8"} {
	integrator GeneralizedAlpha 1.0 0.8
	set color "4"
    } elseif {$intType == "TRBDF2"} {
	set color "5"
	integrator TRBDF2
    } elseif {$intType == "CentralDifference"} {
	set color "o-4"
	integrator CentralDifference
	algorithm Linear
    }

    system ProfileSPD
    numberer RCM
    analysis Transient
    
    set t 0.0
    set ok 0.0

    recorder Node -file nodeLong$intType.out -time -node 2 -dof 1 $responseQuantity
    record

    while {$ok == 0 && $t < $maxT} {
	set ok [analyze 1 $dT]
	if {$ok != 0} {
	    test NormDispIncr 1.0e-12  100 0
	    algorithm ModifiedNewton -initial
	    set ok [analyze 1 .01]
	    test NormDispIncr 1.0e-12  10 
	    algorithm Newton
	}
	
	set t [getTime]
    }
    puts $mFile "load nodeLong$intType.out"
    puts $mFile "figure;"
    puts $mFile "plot(nodeLong$intType\(:,1\),nodeLong$intType\(:,2\))";
    puts $mFile "xlabel(\"Time\");"
    puts $mFile "ylabel(\"$responseQuantity\");"
    if {$intType == "NewmarkGamma"} {
	puts $mFile "title(\"Newmark$gamma\");"
    } else {
	puts $mFile "title(\"$intType\");"
    }
    incr count
}

close $mFile


    
