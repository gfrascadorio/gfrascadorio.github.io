
ClearAll[ruleTableMaker, assocTableMaker, datasetMaker]
ruleListMaker[colNames_] := Thread[colNames -> #] & /@ # &
assocListMaker[colNames_] := 
    Association@Thread[colNames -> #] & /@ # &
datasetMaker[colNames_] := Dataset[assocListMaker[colNames]@#] &

Block[ {$AssertFunction},
        (* Temporarily reassign $AssertFunction *)
        $AssertFunction = Message[Assert::asrtf, HoldForm@@#]&
        Assert[False];
]
