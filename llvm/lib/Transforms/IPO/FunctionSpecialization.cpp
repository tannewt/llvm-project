//===- FunctionSpecialization.cpp - Function Specialization ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This specialises functions with constant parameters. Constant parameters
// like function pointers and constant globals are propagated to the callee by
// specializing the function. The main benefit of this pass at the moment is
// that indirect calls are transformed into direct calls, which provides inline
// opportunities that the inliner would not have been able to achieve. That's
// why function specialisation is run before the inliner in the optimisation
// pipeline; that is by design. Otherwise, we would only benefit from constant
// passing, which is a valid use-case too, but hasn't been explored much in
// terms of performance uplifts, cost-model and compile-time impact.
//
// Current limitations:
// - It does not yet handle integer ranges. We do support "literal constants",
//   but that's off by default under an option.
// - The cost-model could be further looked into (it mainly focuses on inlining
//   benefits),
//
// Ideas:
// - With a function specialization attribute for arguments, we could have
//   a direct way to steer function specialization, avoiding the cost-model,
//   and thus control compile-times / code-size.
//
// Todos:
// - Specializing recursive functions relies on running the transformation a
//   number of times, which is controlled by option
//   `func-specialization-max-iters`. Thus, increasing this value and the
//   number of iterations, will linearly increase the number of times recursive
//   functions get specialized, see also the discussion in
//   https://reviews.llvm.org/D106426 for details. Perhaps there is a
//   compile-time friendlier way to control/limit the number of specialisations
//   for recursive functions.
// - Don't transform the function if function specialization does not trigger;
//   the SCCPSolver may make IR changes.
//
// References:
// - 2021 LLVM Dev Mtg “Introducing function specialisation, and can we enable
//   it by default?”, https://www.youtube.com/watch?v=zJiCjeXgV5Q
//
//===----------------------------------------------------------------------===//

#include "llvm/Transforms/IPO/FunctionSpecialization.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/Analysis/CodeMetrics.h"
#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/Analysis/InlineCost.h"
#include "llvm/Analysis/InstructionSimplify.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/Analysis/ValueLattice.h"
#include "llvm/Analysis/ValueLatticeUtils.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/ConstantFold.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Transforms/Scalar/SCCP.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/SCCPSolver.h"
#include "llvm/Transforms/Utils/SizeOpts.h"
#include <cmath>

using namespace llvm;

#define DEBUG_TYPE "function-specialization"

STATISTIC(NumSpecsCreated, "Number of specializations created");

static cl::opt<bool> ForceSpecialization(
    "force-specialization", cl::init(false), cl::Hidden, cl::desc(
    "Force function specialization for every call site with a constant "
    "argument"));

static cl::opt<unsigned> MaxClones(
    "funcspec-max-clones", cl::init(3), cl::Hidden, cl::desc(
    "The maximum number of clones allowed for a single function "
    "specialization"));

static cl::opt<unsigned> MinFunctionSize(
    "funcspec-min-function-size", cl::init(100), cl::Hidden, cl::desc(
    "Don't specialize functions that have less than this number of "
    "instructions"));

static cl::opt<bool> SpecializeOnAddress(
    "funcspec-on-address", cl::init(false), cl::Hidden, cl::desc(
    "Enable function specialization on the address of global values"));

// Disabled by default as it can significantly increase compilation times.
//
// https://llvm-compile-time-tracker.com
// https://github.com/nikic/llvm-compile-time-tracker
static cl::opt<bool> SpecializeLiteralConstant(
    "funcspec-for-literal-constant", cl::init(false), cl::Hidden, cl::desc(
    "Enable specialization of functions that take a literal constant as an "
    "argument"));

// Estimates the instruction cost of all the basic blocks in \p WorkList.
// The successors of such blocks are added to the list as long as they are
// executable and they have a unique predecessor. \p WorkList represents
// the basic blocks of a specialization which become dead once we replace
// instructions that are known to be constants. The aim here is to estimate
// the combination of size and latency savings in comparison to the non
// specialized version of the function.
static Cost estimateBasicBlocks(SmallVectorImpl<BasicBlock *> &WorkList,
                                ConstMap &KnownConstants, SCCPSolver &Solver,
                                BlockFrequencyInfo &BFI,
                                TargetTransformInfo &TTI) {
  Cost Bonus = 0;

  // Accumulate the instruction cost of each basic block weighted by frequency.
  while (!WorkList.empty()) {
    BasicBlock *BB = WorkList.pop_back_val();

    uint64_t Weight = BFI.getBlockFreq(BB).getFrequency() /
                      BFI.getEntryFreq();
    if (!Weight)
      continue;

    for (Instruction &I : *BB) {
      // Disregard SSA copies.
      if (auto *II = dyn_cast<IntrinsicInst>(&I))
        if (II->getIntrinsicID() == Intrinsic::ssa_copy)
          continue;
      // If it's a known constant we have already accounted for it.
      if (KnownConstants.contains(&I))
        continue;

      Bonus += Weight *
          TTI.getInstructionCost(&I, TargetTransformInfo::TCK_SizeAndLatency);

      LLVM_DEBUG(dbgs() << "FnSpecialization:     Bonus " << Bonus
                        << " after user " << I << "\n");
    }

    // Keep adding dead successors to the list as long as they are
    // executable and they have a unique predecessor.
    for (BasicBlock *SuccBB : successors(BB))
      if (Solver.isBlockExecutable(SuccBB) &&
          SuccBB->getUniquePredecessor() == BB)
        WorkList.push_back(SuccBB);
  }
  return Bonus;
}

static Constant *findConstantFor(Value *V, ConstMap &KnownConstants) {
  if (auto It = KnownConstants.find(V); It != KnownConstants.end())
    return It->second;
  return nullptr;
}

Cost InstCostVisitor::getUserBonus(Instruction *User, Value *Use, Constant *C) {
  // Cache the iterator before visiting.
  LastVisited = KnownConstants.insert({Use, C}).first;

  if (auto *I = dyn_cast<SwitchInst>(User))
    return estimateSwitchInst(*I);

  if (auto *I = dyn_cast<BranchInst>(User))
    return estimateBranchInst(*I);

  C = visit(*User);
  if (!C)
    return 0;

  KnownConstants.insert({User, C});

  uint64_t Weight = BFI.getBlockFreq(User->getParent()).getFrequency() /
                    BFI.getEntryFreq();
  if (!Weight)
    return 0;

  Cost Bonus = Weight *
      TTI.getInstructionCost(User, TargetTransformInfo::TCK_SizeAndLatency);

  LLVM_DEBUG(dbgs() << "FnSpecialization:     Bonus " << Bonus
                    << " for user " << *User << "\n");

  for (auto *U : User->users())
    if (auto *UI = dyn_cast<Instruction>(U))
      if (Solver.isBlockExecutable(UI->getParent()))
        Bonus += getUserBonus(UI, User, C);

  return Bonus;
}

Cost InstCostVisitor::estimateSwitchInst(SwitchInst &I) {
  if (I.getCondition() != LastVisited->first)
    return 0;

  auto *C = cast<ConstantInt>(LastVisited->second);
  BasicBlock *Succ = I.findCaseValue(C)->getCaseSuccessor();
  // Initialize the worklist with the dead basic blocks. These are the
  // destination labels which are different from the one corresponding
  // to \p C. They should be executable and have a unique predecessor.
  SmallVector<BasicBlock *> WorkList;
  for (const auto &Case : I.cases()) {
    BasicBlock *BB = Case.getCaseSuccessor();
    if (BB == Succ || !Solver.isBlockExecutable(BB) ||
        BB->getUniquePredecessor() != I.getParent())
      continue;
    WorkList.push_back(BB);
  }

  return estimateBasicBlocks(WorkList, KnownConstants, Solver, BFI, TTI);
}

Cost InstCostVisitor::estimateBranchInst(BranchInst &I) {
  if (I.getCondition() != LastVisited->first)
    return 0;

  BasicBlock *Succ = I.getSuccessor(LastVisited->second->isOneValue());
  // Initialize the worklist with the dead successor as long as
  // it is executable and has a unique predecessor.
  SmallVector<BasicBlock *> WorkList;
  if (Solver.isBlockExecutable(Succ) &&
      Succ->getUniquePredecessor() == I.getParent())
    WorkList.push_back(Succ);

  return estimateBasicBlocks(WorkList, KnownConstants, Solver, BFI, TTI);
}

Constant *InstCostVisitor::visitLoadInst(LoadInst &I) {
  if (isa<ConstantPointerNull>(LastVisited->second))
    return nullptr;
  return ConstantFoldLoadFromConstPtr(LastVisited->second, I.getType(), DL);
}

Constant *InstCostVisitor::visitGetElementPtrInst(GetElementPtrInst &I) {
  SmallVector<Value *, 8> Operands;
  Operands.reserve(I.getNumOperands());

  for (unsigned Idx = 0, E = I.getNumOperands(); Idx != E; ++Idx) {
    Value *V = I.getOperand(Idx);
    auto *C = dyn_cast<Constant>(V);
    if (!C)
      C = findConstantFor(V, KnownConstants);
    if (!C)
      return nullptr;
    Operands.push_back(C);
  }

  auto *Ptr = cast<Constant>(Operands[0]);
  auto Ops = ArrayRef(Operands.begin() + 1, Operands.end());
  return ConstantFoldGetElementPtr(I.getSourceElementType(), Ptr,
                                   I.isInBounds(), std::nullopt, Ops);
}

Constant *InstCostVisitor::visitSelectInst(SelectInst &I) {
  if (I.getCondition() != LastVisited->first)
    return nullptr;

  Value *V = LastVisited->second->isZeroValue() ? I.getFalseValue()
                                                : I.getTrueValue();
  auto *C = dyn_cast<Constant>(V);
  if (!C)
    C = findConstantFor(V, KnownConstants);
  return C;
}

Constant *InstCostVisitor::visitCastInst(CastInst &I) {
  return ConstantFoldCastOperand(I.getOpcode(), LastVisited->second,
                                 I.getType(), DL);
}

Constant *InstCostVisitor::visitCmpInst(CmpInst &I) {
  bool Swap = I.getOperand(1) == LastVisited->first;
  Value *V = Swap ? I.getOperand(0) : I.getOperand(1);
  auto *Other = dyn_cast<Constant>(V);
  if (!Other)
    Other = findConstantFor(V, KnownConstants);

  if (!Other)
    return nullptr;

  Constant *Const = LastVisited->second;
  return Swap ?
        ConstantFoldCompareInstOperands(I.getPredicate(), Other, Const, DL)
      : ConstantFoldCompareInstOperands(I.getPredicate(), Const, Other, DL);
}

Constant *InstCostVisitor::visitUnaryOperator(UnaryOperator &I) {
  return ConstantFoldUnaryOpOperand(I.getOpcode(), LastVisited->second, DL);
}

Constant *InstCostVisitor::visitBinaryOperator(BinaryOperator &I) {
  bool Swap = I.getOperand(1) == LastVisited->first;
  Value *V = Swap ? I.getOperand(0) : I.getOperand(1);
  auto *Other = dyn_cast<Constant>(V);
  if (!Other)
    Other = findConstantFor(V, KnownConstants);

  if (!Other)
    return nullptr;

  Constant *Const = LastVisited->second;
  return dyn_cast_or_null<Constant>(Swap ?
        simplifyBinOp(I.getOpcode(), Other, Const, SimplifyQuery(DL))
      : simplifyBinOp(I.getOpcode(), Const, Other, SimplifyQuery(DL)));
}

Constant *FunctionSpecializer::getPromotableAlloca(AllocaInst *Alloca,
                                                   CallInst *Call) {
  Value *StoreValue = nullptr;
  for (auto *User : Alloca->users()) {
    // We can't use llvm::isAllocaPromotable() as that would fail because of
    // the usage in the CallInst, which is what we check here.
    if (User == Call)
      continue;
    if (auto *Bitcast = dyn_cast<BitCastInst>(User)) {
      if (!Bitcast->hasOneUse() || *Bitcast->user_begin() != Call)
        return nullptr;
      continue;
    }

    if (auto *Store = dyn_cast<StoreInst>(User)) {
      // This is a duplicate store, bail out.
      if (StoreValue || Store->isVolatile())
        return nullptr;
      StoreValue = Store->getValueOperand();
      continue;
    }
    // Bail if there is any other unknown usage.
    return nullptr;
  }

  if (!StoreValue)
    return nullptr;

  return getCandidateConstant(StoreValue);
}

// A constant stack value is an AllocaInst that has a single constant
// value stored to it. Return this constant if such an alloca stack value
// is a function argument.
Constant *FunctionSpecializer::getConstantStackValue(CallInst *Call,
                                                     Value *Val) {
  if (!Val)
    return nullptr;
  Val = Val->stripPointerCasts();
  if (auto *ConstVal = dyn_cast<ConstantInt>(Val))
    return ConstVal;
  auto *Alloca = dyn_cast<AllocaInst>(Val);
  if (!Alloca || !Alloca->getAllocatedType()->isIntegerTy())
    return nullptr;
  return getPromotableAlloca(Alloca, Call);
}

// To support specializing recursive functions, it is important to propagate
// constant arguments because after a first iteration of specialisation, a
// reduced example may look like this:
//
//     define internal void @RecursiveFn(i32* arg1) {
//       %temp = alloca i32, align 4
//       store i32 2 i32* %temp, align 4
//       call void @RecursiveFn.1(i32* nonnull %temp)
//       ret void
//     }
//
// Before a next iteration, we need to propagate the constant like so
// which allows further specialization in next iterations.
//
//     @funcspec.arg = internal constant i32 2
//
//     define internal void @someFunc(i32* arg1) {
//       call void @otherFunc(i32* nonnull @funcspec.arg)
//       ret void
//     }
//
void FunctionSpecializer::promoteConstantStackValues() {
  // Iterate over the argument tracked functions see if there
  // are any new constant values for the call instruction via
  // stack variables.
  for (Function &F : M) {
    if (!Solver.isArgumentTrackedFunction(&F))
      continue;

    for (auto *User : F.users()) {

      auto *Call = dyn_cast<CallInst>(User);
      if (!Call)
        continue;

      if (!Solver.isBlockExecutable(Call->getParent()))
        continue;

      bool Changed = false;
      for (const Use &U : Call->args()) {
        unsigned Idx = Call->getArgOperandNo(&U);
        Value *ArgOp = Call->getArgOperand(Idx);
        Type *ArgOpType = ArgOp->getType();

        if (!Call->onlyReadsMemory(Idx) || !ArgOpType->isPointerTy())
          continue;

        auto *ConstVal = getConstantStackValue(Call, ArgOp);
        if (!ConstVal)
          continue;

        Value *GV = new GlobalVariable(M, ConstVal->getType(), true,
                                       GlobalValue::InternalLinkage, ConstVal,
                                       "funcspec.arg");
        if (ArgOpType != ConstVal->getType())
          GV = ConstantExpr::getBitCast(cast<Constant>(GV), ArgOpType);

        Call->setArgOperand(Idx, GV);
        Changed = true;
      }

      // Add the changed CallInst to Solver Worklist
      if (Changed)
        Solver.visitCall(*Call);
    }
  }
}

// ssa_copy intrinsics are introduced by the SCCP solver. These intrinsics
// interfere with the promoteConstantStackValues() optimization.
static void removeSSACopy(Function &F) {
  for (BasicBlock &BB : F) {
    for (Instruction &Inst : llvm::make_early_inc_range(BB)) {
      auto *II = dyn_cast<IntrinsicInst>(&Inst);
      if (!II)
        continue;
      if (II->getIntrinsicID() != Intrinsic::ssa_copy)
        continue;
      Inst.replaceAllUsesWith(II->getOperand(0));
      Inst.eraseFromParent();
    }
  }
}

/// Remove any ssa_copy intrinsics that may have been introduced.
void FunctionSpecializer::cleanUpSSA() {
  for (Function *F : Specializations)
    removeSSACopy(*F);
}


template <> struct llvm::DenseMapInfo<SpecSig> {
  static inline SpecSig getEmptyKey() { return {~0U, {}}; }

  static inline SpecSig getTombstoneKey() { return {~1U, {}}; }

  static unsigned getHashValue(const SpecSig &S) {
    return static_cast<unsigned>(hash_value(S));
  }

  static bool isEqual(const SpecSig &LHS, const SpecSig &RHS) {
    return LHS == RHS;
  }
};

FunctionSpecializer::~FunctionSpecializer() {
  LLVM_DEBUG(
    if (NumSpecsCreated > 0)
      dbgs() << "FnSpecialization: Created " << NumSpecsCreated
             << " specializations in module " << M.getName() << "\n");
  // Eliminate dead code.
  removeDeadFunctions();
  cleanUpSSA();
}

/// Attempt to specialize functions in the module to enable constant
/// propagation across function boundaries.
///
/// \returns true if at least one function is specialized.
bool FunctionSpecializer::run() {
  // Find possible specializations for each function.
  SpecMap SM;
  SmallVector<Spec, 32> AllSpecs;
  unsigned NumCandidates = 0;
  for (Function &F : M) {
    if (!isCandidateFunction(&F))
      continue;

    Cost SpecCost = getSpecializationCost(&F);
    if (!SpecCost.isValid()) {
      LLVM_DEBUG(dbgs() << "FnSpecialization: Invalid specialization cost for "
                        << F.getName() << "\n");
      continue;
    }

    LLVM_DEBUG(dbgs() << "FnSpecialization: Specialization cost for "
                      << F.getName() << " is " << SpecCost << "\n");

    if (!findSpecializations(&F, SpecCost, AllSpecs, SM)) {
      LLVM_DEBUG(
          dbgs() << "FnSpecialization: No possible specializations found for "
                 << F.getName() << "\n");
      continue;
    }

    ++NumCandidates;
  }

  if (!NumCandidates) {
    LLVM_DEBUG(
        dbgs()
        << "FnSpecialization: No possible specializations found in module\n");
    return false;
  }

  // Choose the most profitable specialisations, which fit in the module
  // specialization budget, which is derived from maximum number of
  // specializations per specialization candidate function.
  auto CompareScore = [&AllSpecs](unsigned I, unsigned J) {
    return AllSpecs[I].Score > AllSpecs[J].Score;
  };
  const unsigned NSpecs =
      std::min(NumCandidates * MaxClones, unsigned(AllSpecs.size()));
  SmallVector<unsigned> BestSpecs(NSpecs + 1);
  std::iota(BestSpecs.begin(), BestSpecs.begin() + NSpecs, 0);
  if (AllSpecs.size() > NSpecs) {
    LLVM_DEBUG(dbgs() << "FnSpecialization: Number of candidates exceed "
                      << "the maximum number of clones threshold.\n"
                      << "FnSpecialization: Specializing the "
                      << NSpecs
                      << " most profitable candidates.\n");
    std::make_heap(BestSpecs.begin(), BestSpecs.begin() + NSpecs, CompareScore);
    for (unsigned I = NSpecs, N = AllSpecs.size(); I < N; ++I) {
      BestSpecs[NSpecs] = I;
      std::push_heap(BestSpecs.begin(), BestSpecs.end(), CompareScore);
      std::pop_heap(BestSpecs.begin(), BestSpecs.end(), CompareScore);
    }
  }

  LLVM_DEBUG(dbgs() << "FnSpecialization: List of specializations \n";
             for (unsigned I = 0; I < NSpecs; ++I) {
               const Spec &S = AllSpecs[BestSpecs[I]];
               dbgs() << "FnSpecialization: Function " << S.F->getName()
                      << " , score " << S.Score << "\n";
               for (const ArgInfo &Arg : S.Sig.Args)
                 dbgs() << "FnSpecialization:   FormalArg = "
                        << Arg.Formal->getNameOrAsOperand()
                        << ", ActualArg = " << Arg.Actual->getNameOrAsOperand()
                        << "\n";
             });

  // Create the chosen specializations.
  SmallPtrSet<Function *, 8> OriginalFuncs;
  SmallVector<Function *> Clones;
  for (unsigned I = 0; I < NSpecs; ++I) {
    Spec &S = AllSpecs[BestSpecs[I]];
    S.Clone = createSpecialization(S.F, S.Sig);

    // Update the known call sites to call the clone.
    for (CallBase *Call : S.CallSites) {
      LLVM_DEBUG(dbgs() << "FnSpecialization: Redirecting " << *Call
                        << " to call " << S.Clone->getName() << "\n");
      Call->setCalledFunction(S.Clone);
    }

    Clones.push_back(S.Clone);
    OriginalFuncs.insert(S.F);
  }

  Solver.solveWhileResolvedUndefsIn(Clones);

  // Update the rest of the call sites - these are the recursive calls, calls
  // to discarded specialisations and calls that may match a specialisation
  // after the solver runs.
  for (Function *F : OriginalFuncs) {
    auto [Begin, End] = SM[F];
    updateCallSites(F, AllSpecs.begin() + Begin, AllSpecs.begin() + End);
  }

  for (Function *F : Clones) {
    if (F->getReturnType()->isVoidTy())
      continue;
    if (F->getReturnType()->isStructTy()) {
      auto *STy = cast<StructType>(F->getReturnType());
      if (!Solver.isStructLatticeConstant(F, STy))
        continue;
    } else {
      auto It = Solver.getTrackedRetVals().find(F);
      assert(It != Solver.getTrackedRetVals().end() &&
             "Return value ought to be tracked");
      if (SCCPSolver::isOverdefined(It->second))
        continue;
    }
    for (User *U : F->users()) {
      if (auto *CS = dyn_cast<CallBase>(U)) {
        //The user instruction does not call our function.
        if (CS->getCalledFunction() != F)
          continue;
        Solver.resetLatticeValueFor(CS);
      }
    }
  }

  // Rerun the solver to notify the users of the modified callsites.
  Solver.solveWhileResolvedUndefs();

  promoteConstantStackValues();
  return true;
}

void FunctionSpecializer::removeDeadFunctions() {
  for (Function *F : FullySpecialized) {
    LLVM_DEBUG(dbgs() << "FnSpecialization: Removing dead function "
                      << F->getName() << "\n");
    if (FAM)
      FAM->clear(*F, F->getName());
    F->eraseFromParent();
  }
  FullySpecialized.clear();
}

// Compute the code metrics for function \p F.
CodeMetrics &FunctionSpecializer::analyzeFunction(Function *F) {
  auto I = FunctionMetrics.insert({F, CodeMetrics()});
  CodeMetrics &Metrics = I.first->second;
  if (I.second) {
    // The code metrics were not cached.
    SmallPtrSet<const Value *, 32> EphValues;
    CodeMetrics::collectEphemeralValues(F, &(GetAC)(*F), EphValues);
    for (BasicBlock &BB : *F)
      Metrics.analyzeBasicBlock(&BB, (GetTTI)(*F), EphValues);
  }
  return Metrics;
}

/// Clone the function \p F and remove the ssa_copy intrinsics added by
/// the SCCPSolver in the cloned version.
static Function *cloneCandidateFunction(Function *F) {
  ValueToValueMapTy Mappings;
  Function *Clone = CloneFunction(F, Mappings);
  removeSSACopy(*Clone);
  return Clone;
}

bool FunctionSpecializer::findSpecializations(Function *F, Cost SpecCost,
                                              SmallVectorImpl<Spec> &AllSpecs,
                                              SpecMap &SM) {
  // A mapping from a specialisation signature to the index of the respective
  // entry in the all specialisation array. Used to ensure uniqueness of
  // specialisations.
  DenseMap<SpecSig, unsigned> UniqueSpecs;

  // Get a list of interesting arguments.
  SmallVector<Argument *> Args;
  for (Argument &Arg : F->args())
    if (isArgumentInteresting(&Arg))
      Args.push_back(&Arg);

  if (Args.empty())
    return false;

  for (User *U : F->users()) {
    if (!isa<CallInst>(U) && !isa<InvokeInst>(U))
      continue;
    auto &CS = *cast<CallBase>(U);

    // The user instruction does not call our function.
    if (CS.getCalledFunction() != F)
      continue;

    // If the call site has attribute minsize set, that callsite won't be
    // specialized.
    if (CS.hasFnAttr(Attribute::MinSize))
      continue;

    // If the parent of the call site will never be executed, we don't need
    // to worry about the passed value.
    if (!Solver.isBlockExecutable(CS.getParent()))
      continue;

    // Examine arguments and create a specialisation candidate from the
    // constant operands of this call site.
    SpecSig S;
    for (Argument *A : Args) {
      Constant *C = getCandidateConstant(CS.getArgOperand(A->getArgNo()));
      if (!C)
        continue;
      LLVM_DEBUG(dbgs() << "FnSpecialization: Found interesting argument "
                        << A->getName() << " : " << C->getNameOrAsOperand()
                        << "\n");
      S.Args.push_back({A, C});
    }

    if (S.Args.empty())
      continue;

    // Check if we have encountered the same specialisation already.
    if (auto It = UniqueSpecs.find(S); It != UniqueSpecs.end()) {
      // Existing specialisation. Add the call to the list to rewrite, unless
      // it's a recursive call. A specialisation, generated because of a
      // recursive call may end up as not the best specialisation for all
      // the cloned instances of this call, which result from specialising
      // functions. Hence we don't rewrite the call directly, but match it with
      // the best specialisation once all specialisations are known.
      if (CS.getFunction() == F)
        continue;
      const unsigned Index = It->second;
      AllSpecs[Index].CallSites.push_back(&CS);
    } else {
      // Calculate the specialisation gain.
      Cost Score = 0 - SpecCost;
      InstCostVisitor Visitor = getInstCostVisitorFor(F);
      for (ArgInfo &A : S.Args)
        Score += getSpecializationBonus(A.Formal, A.Actual, Visitor);

      // Discard unprofitable specialisations.
      if (!ForceSpecialization && Score <= 0)
        continue;

      // Create a new specialisation entry.
      auto &Spec = AllSpecs.emplace_back(F, S, Score);
      if (CS.getFunction() != F)
        Spec.CallSites.push_back(&CS);
      const unsigned Index = AllSpecs.size() - 1;
      UniqueSpecs[S] = Index;
      if (auto [It, Inserted] = SM.try_emplace(F, Index, Index + 1); !Inserted)
        It->second.second = Index + 1;
    }
  }

  return !UniqueSpecs.empty();
}

bool FunctionSpecializer::isCandidateFunction(Function *F) {
  if (F->isDeclaration() || F->arg_empty())
    return false;

  if (F->hasFnAttribute(Attribute::NoDuplicate))
    return false;

  // Do not specialize the cloned function again.
  if (Specializations.contains(F))
    return false;

  // If we're optimizing the function for size, we shouldn't specialize it.
  if (F->hasOptSize() ||
      shouldOptimizeForSize(F, nullptr, nullptr, PGSOQueryType::IRPass))
    return false;

  // Exit if the function is not executable. There's no point in specializing
  // a dead function.
  if (!Solver.isBlockExecutable(&F->getEntryBlock()))
    return false;

  // It wastes time to specialize a function which would get inlined finally.
  if (F->hasFnAttribute(Attribute::AlwaysInline))
    return false;

  LLVM_DEBUG(dbgs() << "FnSpecialization: Try function: " << F->getName()
                    << "\n");
  return true;
}

Function *FunctionSpecializer::createSpecialization(Function *F,
                                                    const SpecSig &S) {
  Function *Clone = cloneCandidateFunction(F);

  // The original function does not neccessarily have internal linkage, but the
  // clone must.
  Clone->setLinkage(GlobalValue::InternalLinkage);

  // Initialize the lattice state of the arguments of the function clone,
  // marking the argument on which we specialized the function constant
  // with the given value.
  Solver.setLatticeValueForSpecializationArguments(Clone, S.Args);
  Solver.markBlockExecutable(&Clone->front());
  Solver.addArgumentTrackedFunction(Clone);
  Solver.addTrackedFunction(Clone);

  // Mark all the specialized functions
  Specializations.insert(Clone);
  ++NumSpecsCreated;

  return Clone;
}

/// Compute and return the cost of specializing function \p F.
Cost FunctionSpecializer::getSpecializationCost(Function *F) {
  CodeMetrics &Metrics = analyzeFunction(F);
  // If the code metrics reveal that we shouldn't duplicate the function, we
  // shouldn't specialize it. Set the specialization cost to Invalid.
  // Or if the lines of codes implies that this function is easy to get
  // inlined so that we shouldn't specialize it.
  if (Metrics.notDuplicatable || !Metrics.NumInsts.isValid() ||
      (!ForceSpecialization && !F->hasFnAttribute(Attribute::NoInline) &&
       Metrics.NumInsts < MinFunctionSize))
    return InstructionCost::getInvalid();

  // Otherwise, set the specialization cost to be the cost of all the
  // instructions in the function.
  return Metrics.NumInsts;
}

/// Compute a bonus for replacing argument \p A with constant \p C.
Cost FunctionSpecializer::getSpecializationBonus(Argument *A, Constant *C,
                                                 InstCostVisitor &Visitor) {
  LLVM_DEBUG(dbgs() << "FnSpecialization: Analysing bonus for constant: "
                    << C->getNameOrAsOperand() << "\n");

  Cost TotalCost = 0;
  for (auto *U : A->users())
    if (auto *UI = dyn_cast<Instruction>(U))
      if (Solver.isBlockExecutable(UI->getParent()))
        TotalCost += Visitor.getUserBonus(UI, A, C);

  LLVM_DEBUG(dbgs() << "FnSpecialization:   Accumulated user bonus "
                    << TotalCost << " for argument " << *A << "\n");

  // The below heuristic is only concerned with exposing inlining
  // opportunities via indirect call promotion. If the argument is not a
  // (potentially casted) function pointer, give up.
  Function *CalledFunction = dyn_cast<Function>(C->stripPointerCasts());
  if (!CalledFunction)
    return TotalCost;

  // Get TTI for the called function (used for the inline cost).
  auto &CalleeTTI = (GetTTI)(*CalledFunction);

  // Look at all the call sites whose called value is the argument.
  // Specializing the function on the argument would allow these indirect
  // calls to be promoted to direct calls. If the indirect call promotion
  // would likely enable the called function to be inlined, specializing is a
  // good idea.
  int Bonus = 0;
  for (User *U : A->users()) {
    if (!isa<CallInst>(U) && !isa<InvokeInst>(U))
      continue;
    auto *CS = cast<CallBase>(U);
    if (CS->getCalledOperand() != A)
      continue;
    if (CS->getFunctionType() != CalledFunction->getFunctionType())
      continue;

    // Get the cost of inlining the called function at this call site. Note
    // that this is only an estimate. The called function may eventually
    // change in a way that leads to it not being inlined here, even though
    // inlining looks profitable now. For example, one of its called
    // functions may be inlined into it, making the called function too large
    // to be inlined into this call site.
    //
    // We apply a boost for performing indirect call promotion by increasing
    // the default threshold by the threshold for indirect calls.
    auto Params = getInlineParams();
    Params.DefaultThreshold += InlineConstants::IndirectCallThreshold;
    InlineCost IC =
        getInlineCost(*CS, CalledFunction, Params, CalleeTTI, GetAC, GetTLI);

    // We clamp the bonus for this call to be between zero and the default
    // threshold.
    if (IC.isAlways())
      Bonus += Params.DefaultThreshold;
    else if (IC.isVariable() && IC.getCostDelta() > 0)
      Bonus += IC.getCostDelta();

    LLVM_DEBUG(dbgs() << "FnSpecialization:   Inlining bonus " << Bonus
                      << " for user " << *U << "\n");
  }

  return TotalCost + Bonus;
}

/// Determine if it is possible to specialise the function for constant values
/// of the formal parameter \p A.
bool FunctionSpecializer::isArgumentInteresting(Argument *A) {
  // No point in specialization if the argument is unused.
  if (A->user_empty())
    return false;

  Type *Ty = A->getType();
  if (!Ty->isPointerTy() && (!SpecializeLiteralConstant ||
      (!Ty->isIntegerTy() && !Ty->isFloatingPointTy() && !Ty->isStructTy())))
    return false;

  // SCCP solver does not record an argument that will be constructed on
  // stack.
  if (A->hasByValAttr() && !A->getParent()->onlyReadsMemory())
    return false;

  // For non-argument-tracked functions every argument is overdefined.
  if (!Solver.isArgumentTrackedFunction(A->getParent()))
    return true;

  // Check the lattice value and decide if we should attemt to specialize,
  // based on this argument. No point in specialization, if the lattice value
  // is already a constant.
  bool IsOverdefined = Ty->isStructTy()
    ? any_of(Solver.getStructLatticeValueFor(A), SCCPSolver::isOverdefined)
    : SCCPSolver::isOverdefined(Solver.getLatticeValueFor(A));

  LLVM_DEBUG(
    if (IsOverdefined)
      dbgs() << "FnSpecialization: Found interesting parameter "
             << A->getNameOrAsOperand() << "\n";
    else
      dbgs() << "FnSpecialization: Nothing to do, parameter "
             << A->getNameOrAsOperand() << " is already constant\n";
  );
  return IsOverdefined;
}

/// Check if the value \p V  (an actual argument) is a constant or can only
/// have a constant value. Return that constant.
Constant *FunctionSpecializer::getCandidateConstant(Value *V) {
  if (isa<PoisonValue>(V))
    return nullptr;

  // Select for possible specialisation values that are constants or
  // are deduced to be constants or constant ranges with a single element.
  Constant *C = dyn_cast<Constant>(V);
  if (!C)
    C = Solver.getConstantOrNull(V);

  // Don't specialize on (anything derived from) the address of a non-constant
  // global variable, unless explicitly enabled.
  if (C && C->getType()->isPointerTy() && !C->isNullValue())
    if (auto *GV = dyn_cast<GlobalVariable>(getUnderlyingObject(C));
        GV && !(GV->isConstant() || SpecializeOnAddress))
      return nullptr;

  return C;
}

void FunctionSpecializer::updateCallSites(Function *F, const Spec *Begin,
                                          const Spec *End) {
  // Collect the call sites that need updating.
  SmallVector<CallBase *> ToUpdate;
  for (User *U : F->users())
    if (auto *CS = dyn_cast<CallBase>(U);
        CS && CS->getCalledFunction() == F &&
        Solver.isBlockExecutable(CS->getParent()))
      ToUpdate.push_back(CS);

  unsigned NCallsLeft = ToUpdate.size();
  for (CallBase *CS : ToUpdate) {
    bool ShouldDecrementCount = CS->getFunction() == F;

    // Find the best matching specialisation.
    const Spec *BestSpec = nullptr;
    for (const Spec &S : make_range(Begin, End)) {
      if (!S.Clone || (BestSpec && S.Score <= BestSpec->Score))
        continue;

      if (any_of(S.Sig.Args, [CS, this](const ArgInfo &Arg) {
            unsigned ArgNo = Arg.Formal->getArgNo();
            return getCandidateConstant(CS->getArgOperand(ArgNo)) != Arg.Actual;
          }))
        continue;

      BestSpec = &S;
    }

    if (BestSpec) {
      LLVM_DEBUG(dbgs() << "FnSpecialization: Redirecting " << *CS
                        << " to call " << BestSpec->Clone->getName() << "\n");
      CS->setCalledFunction(BestSpec->Clone);
      ShouldDecrementCount = true;
    }

    if (ShouldDecrementCount)
      --NCallsLeft;
  }

  // If the function has been completely specialized, the original function
  // is no longer needed. Mark it unreachable.
  if (NCallsLeft == 0 && Solver.isArgumentTrackedFunction(F)) {
    Solver.markFunctionUnreachable(F);
    FullySpecialized.insert(F);
  }
}
