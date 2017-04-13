# Inspired from example1.cpp from SDPA
p = SDPA.SDPAProblem()
mDIM   = 3
nBlock = 1
SDPA.inputConstraintNumber(p, mDIM)
SDPA.inputBlockNumber(p, nBlock)
SDPA.inputBlockSize(p, 1, 2)
SDPA.inputBlockType(p, 1, SDPA.SDP)

SDPA.initializeUpperTriangleSpace(p)

SDPA.inputCVec(p, 1, 48)
SDPA.inputCVec(p, 2, -8)
SDPA.inputCVec(p, 3, 20)

SDPA.inputElement(p, 0, 1, 1, 1, -11., false)
SDPA.inputElement(p, 0, 1, 2, 2,  23., false)

SDPA.inputElement(p, 1, 1, 1, 1,  10., false)
SDPA.inputElement(p, 1, 1, 1, 2,   4., false)

SDPA.inputElement(p, 2, 1, 2, 2,  -8., false)

SDPA.inputElement(p, 3, 1, 1, 2,  -8., false)
SDPA.inputElement(p, 3, 1, 2, 2,  -2., false)

SDPA.initializeUpperTriangle(p, false)
SDPA.initializeSolve(p)

SDPA.solve(p)

@test SDPA.getIteration(p) == 10
@test isapprox(SDPA.getPrimalObj(p), -41.8999961638664)
@test isapprox(SDPA.getDualObj(p), -41.89999999999982)
@test SDPA.getPrimalError(p) < 1e-10
@test SDPA.getDualError(p) < 1e-10

SDPA.terminate(p)
