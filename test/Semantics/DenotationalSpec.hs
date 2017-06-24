module Semantics.DenotationalSpec
( derivedSymbolValSpec
, bexpValSpec
, denotationalSpec
) where

import Semantics.Denotational
import State.Config as Config
import State.Env as Env
import State.Error
import State.Machine
import State.Program
import State.Tape
import Syntax.Tree
import TestHelper
import Test.Hspec hiding (shouldContain, shouldSatify, shouldThrow)
import Test.HUnit.Lang

type ProgResult a     = IO (Either RuntimeError (Machine a))
type ProgResultConfig = ProgResult Config

-- Runs `derivedSymbolVal` with `sym` in the given config and environment.
evalDerivedSymbol :: DerivedSymbol -> Config -> Env -> ProgResult TapeSymbol
evalDerivedSymbol sym config = runProgram (derivedSymbolVal sym (return config))

-- Runs `bexpVal` with `b` in the given config and environment.
evalBexp :: Bexp -> Config -> Env -> ProgResult Bool
evalBexp b config = runProgram (bexpVal b (return config))

-- Runs `s` in config with the empty environment.
evalSemantics :: Stm -> Config -> ProgResultConfig
evalSemantics s config = runProgram (evalStm s (return config)) Env.empty

-- Asserts that a runtime error was thrown.
shouldThrow :: (Show a) => ProgResult a -> RuntimeError -> Expectation
shouldThrow r expected = do
    x <- r
    case x of
        Left err   -> err `shouldBe` expected
        Right mach -> assertFailure ("Expected err, got machine: " ++ (show mach))

-- Asserts that when the semantics have finished being evaulated, the resulting
-- machine satisfies the given predicate.
machShouldSatify :: (Eq a, Show a) => ProgResult a -> (Machine a -> Bool) -> Expectation
machShouldSatify r predicate = do
     x <- r
     case x of
         Left  err  -> assertFailure ("Expected machine, got error: " ++ (show err))
         Right mach -> mach `shouldSatisfy` predicate

-- Asserts that when the semantics have finished being evaulated, the value
-- wrapped in the machine satisfies the predicate.
shouldSatify :: (Eq a, Show a) => ProgResult a -> (a -> Bool) -> Expectation
shouldSatify r predicate = machShouldSatify r f where
    f = machine False False predicate

-- Asserts that when the semantics have finished being evaulated, the machine
-- contains the given value.
shouldContain :: (Eq a, Show a) => ProgResult a -> a -> Expectation
shouldContain r sym = shouldSatify r (== sym)

-- Asserts that when the semantics have finished being evauluated, the position
-- of the read-write head is in the given position.
shouldBeAt :: ProgResultConfig -> Pos -> Expectation
shouldBeAt r p = shouldSatify r predicate where
    predicate c = pos c == p
    predicate _ = False

-- Asserts that the tape has the string `str` at the start of the tape.
shouldRead :: ProgResultConfig -> [TapeSymbol] -> Expectation
shouldRead r syms = shouldSatify r predicate where
    predicate c = tapeShouldRead (tape c) syms
    predicate _ = False

-- Asserts that the machine halted in the accepting state.
shouldAccept :: ProgResultConfig -> Expectation
shouldAccept r = machShouldSatify r (== HaltA)

-- Asserts that the machine halted in the rejecting state.
shouldReject :: ProgResultConfig -> Expectation
shouldReject r = machShouldSatify r (== HaltR)

derivedSymbolValSpec :: Spec
derivedSymbolValSpec = do
    let testConfig = right (Config.fromString "abc")
        testEnv    = Env.addVar "x" '1' Env.empty
    describe "derivedSymbolVal" $ do
        it "reads the symbol under the read-write head" $ do
            let result = evalDerivedSymbol Read testConfig testEnv
            result `shouldContain` 'b'

        it "returns the literal" $ do
            let result = evalDerivedSymbol (Literal 'm') testConfig testEnv
            result `shouldContain` 'm'

        it "returns the value of a variable" $ do
            let result = evalDerivedSymbol (Var "x") testConfig testEnv
            result `shouldContain` '1'

        it "fails if the variable is not defined" $ do
            let result = evalDerivedSymbol (Var "undef") testConfig testEnv
            result `shouldThrow` (UndefVar "undef")

bexpValSpec :: Spec
bexpValSpec = do
    let testConfig = right (Config.fromString "abc")
        testEnv    = Env.addVar "x" '1' Env.empty
    describe "bexpVal" $ do
        it "evaluates TRUE" $ do
            let result = evalBexp TRUE testConfig testEnv
            result `shouldContain` True

        it "evaluates FALSE" $ do
            let result = evalBexp FALSE testConfig testEnv
            result `shouldContain` False

        it "evaluates not" $ do
            let result = evalBexp (Not TRUE) testConfig testEnv
            result `shouldContain` False

        it "evaluates and" $ do
            let ff = evalBexp (And FALSE FALSE) testConfig testEnv
                ft = evalBexp (And FALSE TRUE) testConfig testEnv
                tf = evalBexp (And TRUE FALSE) testConfig testEnv
                tt = evalBexp (And TRUE TRUE) testConfig testEnv
            ff `shouldContain` False
            ft `shouldContain` False
            tf `shouldContain` False
            tt `shouldContain` True

        it "evaluates or" $ do
            let ff = evalBexp (Or FALSE FALSE) testConfig testEnv
                ft = evalBexp (Or FALSE TRUE) testConfig testEnv
                tf = evalBexp (Or TRUE FALSE) testConfig testEnv
                tt = evalBexp (Or TRUE TRUE) testConfig testEnv
            ff `shouldContain` False
            ft `shouldContain` True
            tf `shouldContain` True
            tt `shouldContain` True

        it "evaluates <=" $ do
            let b1      = Le (Read) (Literal 'c') -- The current symbol is 'b'.
                b2      = Le (Read) (Literal 'a')
                result1 = evalBexp b1 testConfig testEnv
                result2 = evalBexp b2 testConfig testEnv
            result1 `shouldContain` True
            result2 `shouldContain` False

        it "evaluates ==" $ do
            let b1      = Eq (Read) (Literal 'b') -- The current symbol is 'b'.
                b2      = Eq (Read) (Literal '#')
                result1 = evalBexp b1 testConfig testEnv
                result2 = evalBexp b2 testConfig testEnv
            result1 `shouldContain` True
            result2 `shouldContain` False

denotationalSpec :: Spec
denotationalSpec = do
    describe "evalStm" $ do
        leftSpec
        rightSpec
        writeSpec
        acceptSpec
        rejectSpec
        ifSpec
        whileSpec
        varDeclSpec
        funcCallSpec
        compSpec

leftSpec :: Spec
leftSpec = do
    let testConfig = right (Config.fromString "abc")
    context "left" $ do
        it "moves the read-write head left" $ do
            evalSemantics (MoveLeft) testConfig `shouldBeAt` 0

rightSpec :: Spec
rightSpec = do
    let testConfig = right (Config.fromString "abc")
    context "right" $ do
        it "moves the read-write head right" $ do
            evalSemantics (MoveRight) testConfig `shouldBeAt` 2

writeSpec :: Spec
writeSpec = do
    let testConfig = right (Config.fromString "abc")
    context "right" $ do
        it "writes to the cell under the read-write head" $ do
            evalSemantics (Write (Literal '2')) testConfig `shouldRead` "a2c"

acceptSpec :: Spec
acceptSpec = do
    let testConfig = right (Config.fromString "abc")
    context "accept" $ do
        it "accepts after evaluating an accept statement" $ do
            shouldAccept $ evalSemantics (Accept) testConfig

rejectSpec :: Spec
rejectSpec = do
    let testConfig = right (Config.fromString "abc")
    context "reject" $ do
        it "rejects after evaluating an accept statement" $ do
            shouldReject $ evalSemantics (Reject) testConfig

ifSpec :: Spec
ifSpec = do
    let testConfig = right (Config.fromString "abc")
    context "evaluating a single if-statement" $ do
        it "performs the first branch" $ do
            let ifStm = If TRUE (Write (Literal '1')) [] Nothing
            evalSemantics ifStm testConfig `shouldRead` "a1c"

        it "performs nothing if predicate is false" $ do
            let ifStm = If FALSE (Write (Literal '1')) [] Nothing
            evalSemantics ifStm testConfig `shouldRead` "abc"

    context "evaluating an if-elseif statement" $ do
        it "performs the first branch" $ do
            let ifStm = If TRUE (Write (Literal '1')) [(TRUE, Write (Literal '2'))] Nothing
            evalSemantics ifStm testConfig `shouldRead` "a1c"

        it "performs the second branch" $ do
            let ifStm = If FALSE (Write (Literal '1')) [(TRUE, Write (Literal '2'))] Nothing
            evalSemantics ifStm testConfig `shouldRead` "a2c"

        it "performs the third branch" $ do
            let ifStm = If FALSE (Write (Literal '1')) [(FALSE, Write (Literal '2')), (TRUE, Write (Literal '3'))] Nothing
            evalSemantics ifStm testConfig `shouldRead` "a3c"

    context "evaluating an if-elseif-else statement" $ do
        it "performs the first branch" $ do
            let ifStm = If TRUE (Write (Literal '1')) [(TRUE, Write (Literal '2'))] (Just (Write (Literal '3')))
            evalSemantics ifStm testConfig `shouldRead` "a1c"

        it "performs the second branch" $ do
            let ifStm = If FALSE (Write (Literal '1')) [(TRUE, Write (Literal '2'))] (Just (Write (Literal '3')))
            evalSemantics ifStm testConfig `shouldRead` "a2c"

        it "performs the else branch" $ do
            let ifStm = If FALSE (Write (Literal '1')) [(FALSE, Write (Literal '2'))] (Just (Write (Literal '3')))
            evalSemantics ifStm testConfig `shouldRead` "a3c"

whileSpec :: Spec
whileSpec = do
    let testConfig = Config.fromString "Ab5#"
    context "evaluating while loop" $ do
        it "does not loop if the condition is false" $ do
            let loop = While FALSE (Write (Literal '1'))
            evalSemantics loop testConfig `shouldRead` "Ab5#"

        it "performs a loop" $ do
            -- Move right until a '#' character is reached.
            let cond = Not (Eq Read (Literal '#'))
                loop = While cond MoveRight
            evalSemantics loop testConfig `shouldBeAt` 3

        -- it "breaks by rejecting" $ do
        --     let loop = While TRUE Reject
        --     shouldReject (evalSemantics loop testConfig)

        -- it "breaks by accepting" $ do
        --     let loop = While TRUE Accept
        --     shouldAccept (evalSemantics loop testConfig)

varDeclSpec :: Spec
varDeclSpec = do
    let testConfig = Config.fromString "abc"
    context "evaluating a variable declaration" $ do
        it "it adds the variable to the environment" $ do
            let decl   = VarDecl "y" (Literal '1')
                ifStm  = If (Eq (Var "y") (Literal '1')) (Write (Literal '#')) [] Nothing
                comp   = Comp decl ifStm
            evalSemantics comp testConfig `shouldRead` "#bc"

funcCallSpec :: Spec
funcCallSpec = do
    let testConfig = Config.fromString "abc"
    context "evaluating a function call" $ do
        it "performs the function" $ do
            let decl = FuncDecl "f" MoveRight
                call = Call "f"
                comp = Comp decl call
            evalSemantics comp testConfig `shouldBeAt` 1

compSpec :: Spec
compSpec = do
    let testConfig = Config.fromString "012"
    context "evaluating a function composition" $ do
        it "composes two statements" $ do
            let comp   = Comp MoveRight (Write (Literal '#'))
                result = evalSemantics comp testConfig
            result `shouldBeAt` 1
            result `shouldRead` "0#2"