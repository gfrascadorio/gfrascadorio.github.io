
ClearAll[ruleMaker, assocMaker, datasetMaker]
ruleMaker[colNames_] := (Thread[colNames -> #]& /@ #) &
assocMaker[colNames_] := (Association@Thread[colNames -> #] & /@ #) &
datasetMaker[colNames_] := (Dataset[assocMaker[colNames]@#]) &
