# Inspired from example1.cpp from SDPA
p = SDPA.SDPAProblem()
mDIM   = 5
nBlock = 3
SDPA.inputConstraintNumber(p, mDIM)
SDPA.inputBlockNumber(p, nBlock)
SDPA.inputBlockSize(p, 1,2)
SDPA.inputBlockSize(p, 2,3)
SDPA.inputBlockSize(p, 3,-2)
SDPA.inputBlockType(p, 1,SDPA.SDP)
SDPA.inputBlockType(p, 2,SDPA.SDP)
SDPA.inputBlockType(p, 3,SDPA.LP)

SDPA.initializeUpperTriangleSpace(p)

SDPA.inputCVec(p, 1,1.1)
SDPA.inputCVec(p, 2,-10)
SDPA.inputCVec(p, 3,6.6)
SDPA.inputCVec(p, 4,19)
SDPA.inputCVec(p, 5,4.1)

# Objective
SDPA.inputElement(p, 0, 1, 1, 1, -1.4, false)
SDPA.inputElement(p, 0, 1, 1, 2, -3.2, false)
SDPA.inputElement(p, 0, 1, 2, 2,  -28, false)

SDPA.inputElement(p, 0, 2, 1, 1,  15, false)
SDPA.inputElement(p, 0, 2, 1, 2, -12, false)
SDPA.inputElement(p, 0, 2, 1, 3, 2.1, false)
SDPA.inputElement(p, 0, 2, 2, 2,  16, false)
SDPA.inputElement(p, 0, 2, 2, 3,-3.8, false)
SDPA.inputElement(p, 0, 2, 3, 3,  15, false)

SDPA.inputElement(p, 0, 3, 1, 1, 1.8, false)
SDPA.inputElement(p, 0, 3, 2, 2,-4.0, false)

# 1st constraint
SDPA.inputElement(p, 1, 1, 1, 1, 0.5, false)
SDPA.inputElement(p, 1, 1, 1, 2, 5.2, false)
SDPA.inputElement(p, 1, 1, 2, 2,-5.3, false)

SDPA.inputElement(p, 1, 2, 1, 1, 7.8, false)
SDPA.inputElement(p, 1, 2, 1, 2,-2.4, false)
SDPA.inputElement(p, 1, 2, 1, 3, 6.0, false)
SDPA.inputElement(p, 1, 2, 2, 2, 4.2, false)
SDPA.inputElement(p, 1, 2, 2, 3, 6.5, false)
SDPA.inputElement(p, 1, 2, 3, 3, 2.1, false)

SDPA.inputElement(p, 1, 3, 1, 1, -4.5, false)
SDPA.inputElement(p, 1, 3, 2, 2, -3.5, false)

# 2nd constraint
SDPA.inputElement(p, 2, 1, 1, 1,  1.7, false)
SDPA.inputElement(p, 2, 1, 1, 2,  7.0, false)
SDPA.inputElement(p, 2, 1, 2, 2, -9.3, false)

SDPA.inputElement(p, 2, 2, 1, 1, -1.9, false)
SDPA.inputElement(p, 2, 2, 1, 2, -0.9, false)
SDPA.inputElement(p, 2, 2, 1, 3, -1.3, false)
SDPA.inputElement(p, 2, 2, 2, 2, -0.8, false)
SDPA.inputElement(p, 2, 2, 2, 3, -2.1, false)
SDPA.inputElement(p, 2, 2, 3, 3,  4.0, false)

SDPA.inputElement(p, 2, 3, 1, 1, -0.2, false)
SDPA.inputElement(p, 2, 3, 2, 2, -3.7, false)

# 3rd constraint
SDPA.inputElement(p, 3, 1, 1, 1,  6.3, false)
SDPA.inputElement(p, 3, 1, 1, 2, -7.5, false)
SDPA.inputElement(p, 3, 1, 2, 2, -3.3, false)

SDPA.inputElement(p, 3, 2, 1, 1,  0.2, false)
SDPA.inputElement(p, 3, 2, 1, 2,  8.8, false)
SDPA.inputElement(p, 3, 2, 1, 3,  5.4, false)
SDPA.inputElement(p, 3, 2, 2, 2,  3.4, false)
SDPA.inputElement(p, 3, 2, 2, 3, -0.4, false)
SDPA.inputElement(p, 3, 2, 3, 3,  7.5, false)

SDPA.inputElement(p, 3, 3, 1, 1, -3.3, false)
SDPA.inputElement(p, 3, 3, 2, 2, -4.0, false)

# 4th constraint
SDPA.inputElement(p, 4, 1, 1, 1, -2.4, false)
SDPA.inputElement(p, 4, 1, 1, 2, -2.5, false)
SDPA.inputElement(p, 4, 1, 2, 2, -2.9, false)

SDPA.inputElement(p, 4, 2, 1, 1,  3.4, false)
SDPA.inputElement(p, 4, 2, 1, 2, -3.2, false)
SDPA.inputElement(p, 4, 2, 1, 3, -4.5, false)
SDPA.inputElement(p, 4, 2, 2, 2,  3.0, false)
SDPA.inputElement(p, 4, 2, 2, 3, -4.8, false)
SDPA.inputElement(p, 4, 2, 3, 3,  3.6, false)

SDPA.inputElement(p, 4, 3, 1, 1, 4.8, false)
SDPA.inputElement(p, 4, 3, 2, 2, 9.7, false)

# 5th constraint
SDPA.inputElement(p, 5, 1, 1, 1, -6.5, false)
SDPA.inputElement(p, 5, 1, 1, 2, -5.4, false)
SDPA.inputElement(p, 5, 1, 2, 2, -6.6, false)

SDPA.inputElement(p, 5, 2, 1, 1,  6.7, false)
SDPA.inputElement(p, 5, 2, 1, 2, -7.2, false)
SDPA.inputElement(p, 5, 2, 1, 3, -3.6, false)
SDPA.inputElement(p, 5, 2, 2, 2,  7.3, false)
SDPA.inputElement(p, 5, 2, 2, 3, -3.0, false)
SDPA.inputElement(p, 5, 2, 3, 3, -1.4, false)

SDPA.inputElement(p, 5, 3, 1, 1, 6.1, false)
SDPA.inputElement(p, 5, 3, 2, 2,-1.5, false)

SDPA.initializeUpperTriangle(p, false)
SDPA.initializeSolve(p)

SDPA.solve(p)

@test SDPA.getIteration(p) == 13
@test isapprox(SDPA.getPrimalObj(p), 32.06269340482402)
@test isapprox(SDPA.getDualObj(p), 32.062692353573865)
@test SDPA.getPrimalError(p) < 1e-10
@test SDPA.getDualError(p) < 1e-10

SDPA.terminate(p)
