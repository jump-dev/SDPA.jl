# Inspired from example1.cpp from SDPA
p = SDPA.SDPAProblem()
mDIM   = 5
nBlock = 3
SDPA.inputConstraintNumber(p, mDIM)
SDPA.inputBlockNumber(p, nBlock)
SDPA.inputBlockSize(p, 1, 2)
SDPA.inputBlockSize(p, 2, 3)
SDPA.inputBlockSize(p, 3, -2)
SDPA.inputBlockType(p, 1, SDPA.SDP)
SDPA.inputBlockType(p, 2, SDPA.SDP)
SDPA.inputBlockType(p, 3, SDPA.LP)

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

# See Section 6.3 of
# SDPA (SemiDefinite Programming Algorithm) User's Manual — Version 6.2.0
# https://pdfs.semanticscholar.org/0332/d0044b09e1212e181bc422f390de05df0c88.pdf Section 6.3
# for the values
@test SDPA.getIteration(p) == 13
@test isapprox(SDPA.getPrimalObj(p), 32.06269340482402)
@test isapprox(SDPA.getDualObj(p), 32.062692353573865)
@test SDPA.getPrimalError(p) < 1e-10
@test SDPA.getDualError(p) < 1e-10

X = SDPA.VarDualSolution(p)
@test isapprox(SDPA.block(X, 1), [+6.392e-08 -9.638e-09;
                      -9.638e-09 +4.539e-08], rtol=1e-4)
@test isapprox(SDPA.block(X, 2), [+7.119e+00 +5.025e+00 +1.916e+00;
                      +5.025e+00 +4.415e+00 +2.506e+00;
                      +1.916e+00 +2.506e+00 +2.048e+00], rtol=1e-4)
@test isapprox(SDPA.block(X, 3), Diagonal([+3.432e-01, +4.391e+00]), rtol=1e-4)

Y = SDPA.PrimalSolution(p)
@test size(Y) == (7, 7)
@test Y[1, 3] == 0
@test_throws BoundsError Y[1, 0]
@test_throws BoundsError SDPA.block(Y, 0)
@test_throws BoundsError SDPA.block(Y, 4)
@test_throws BoundsError SDPA.block(Y, 1)[0, 1]
@test_throws BoundsError SDPA.block(Y, 1)[1, 3]
@test isapprox(SDPA.block(Y, 1), [+2.640e+00 +5.606e-01;
                      +5.606e-01 +3.718e+00], rtol=1e-4)
@test isapprox(Y[6, 6], +4.087e-07, rtol=1e-4)
@test isapprox(SDPA.block(Y, 2), [+7.616e-01 -1.514e+00 +1.139e+00;
                      -1.514e+00 +3.008e+00 -2.264e+00;
                      +1.139e+00 -2.264e+00 +1.705e+00], rtol=1e-3)
@test isapprox(Y[4, 3], -1.514e+00, rtol=1e-3)
@test isapprox(SDPA.block(Y, 3), Diagonal([+4.087e-07, +3.195e-08]), rtol=1e-4)
@test isapprox(Y[6, 6], +4.087e-07, rtol=1e-4)
@test Y[6, 7] == 0

SDPA.terminate(p)
