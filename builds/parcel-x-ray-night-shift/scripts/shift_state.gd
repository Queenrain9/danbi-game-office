extends RefCounted
const SHIFT_SIZE:=8
var case_index:=0
var score:=0
var correct:=0
var critical:=0
var streak:=0
var total_scan_reversals:=0
var total_scans:=0
var shift_cases:Array=[]

func begin_shift(all_cases:Array)->void:
 case_index=0; score=0; correct=0; critical=0; streak=0; total_scan_reversals=0; total_scans=0
 shift_cases=all_cases.duplicate(true); shift_cases.shuffle(); shift_cases=shift_cases.slice(0,SHIFT_SIZE)

func current_case()->Dictionary: return shift_cases[case_index]

func record(choice:String,expected:String,scan_reversals:int,false_pins:int=0,scan_uses:int=0)->Dictionary:
 var ok:=choice==expected
 var delta:=100 if ok else (-180 if choice=="PASS" and expected!="PASS" else -80)
 if ok and expected=="ISOLATE": delta=150
 if ok:
  correct+=1; streak+=1
  if streak>=3: delta+=10
 else:
  streak=0
  if choice=="PASS" and expected!="PASS": critical+=1
 if scan_reversals<=3: delta+=20
 if scan_uses>4: delta-=(scan_uses-4)*10
 delta-=false_pins*5
 total_scan_reversals+=scan_reversals; total_scans+=scan_uses; score+=delta
 return {"correct":ok,"delta":delta}

func advance()->bool:
 case_index+=1
 return case_index>=SHIFT_SIZE

func grade()->String:
 if critical>=2:return "C"
 if correct>=7 and critical==0:return "A"
 if correct>=6:return "B"
 return "C"
