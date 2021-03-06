
<<"../mathematica/dataset-tools.m" 

ClearAll[expit];
expit::template = "expit[logit] ";
expit::usage = % <> "returns the inverse logit value.";
expit[logit_] := 1/(1+Exp[-logit])

Unprotect[Message]
Message[info::tag_] := Print["xxxx"]
ClearAll[mlogit];
mlogit::template = "logit[msg, parms..] ";
mlogit::usage = % <> "prints the msg to the Message stream after insertings parms";
mlogit[msg_, args___] := Module[{},
    info::msg = msg;
    Message[info::msg, args];
]

ClearAll[generateData];
generateData::template = "generateData[n] ";
generateData::usage = % <> "generates n sample data points and returns them in a data frame.";

generateData[n_] := 
    datasetMaker[{"w1","w2","w3","w4","a","y","y1","y0"}] @
        Table[ReleaseHold@#, n]& @
            Hold[Module[{y, y0, y1, a, w1, w2, w3, w4, pa, py, py1},
                w1 = RandomVariate[BinomialDistribution[1, 0.5]];
                w2 = RandomVariate[BinomialDistribution[1, 0.65]];
                w3 = N[RandomVariate[UniformDistribution[{0, 4}]], 3];
                w4 = N[RandomVariate[UniformDistribution[{0, 5}]], 3];
                pa = expit[ -0.4 + 0.2 w2 + 0.15 w3 + 0.2 w4 + 0.15 w2 w4 ];
                mlogit[" w1:``, w2:``, w3:``, w4:``", w1, w2, w3, w4];
                Assert[0 <= pa <= 1];
                a = RandomVariate[BinomialDistribution[1, pa]];
                py[a_] := expit[ -1 + a - 0.1 w1 + 0.3 w2 + 0.25 w3 + 0.2 w4 + 0.15 w2 w4];
                y  = RandomVariate[BinomialDistribution[1, py[a]]];
                y1 = RandomVariate[BinomialDistribution[1, py[1]]];
                y0 = RandomVariate[BinomialDistribution[1, py[0]]];
                {w1,w2,w3,w4,a,y,y1,y0}
            ]]

SeedRandom[7777];
obsData = generateData[100]

