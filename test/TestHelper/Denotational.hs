module TestHelper.Denotational where

import State.Tape as T
import Syntax.Tree
import State.App
import State.Config as Config
import State.Machine
import State.Output
import Semantics.Bexp
import Semantics.Stm
import qualified Test.Hspec as H
import Data.Maybe
import TestHelper.Output
import TestHelper.Config

type AppResult m a = m (Machine a)

evalWith :: (a -> Config -> App m b) -> a -> Config -> AppResult m b
evalWith f x config = evalApp (f x config)

-- Runs `bexpVal` with `b` in the given config and environment.
evalBexp :: (Monad m) => Bexp -> Config -> AppResult m Bool
evalBexp = evalWith bexpVal' where
    bexpVal' b c = fmap fst (bexpVal b c)

evalSemantics :: (MonadOutput m) => Stm -> Config -> AppResult m Config
evalSemantics = evalWith evalStm

-- Asserts that when the semantics have finished being evaulated, the value
-- wrapped in the machine satisfies the predicate.
shouldSatisfy :: (Eq a, Show a) => IO (Machine a) -> (a -> Bool) -> H.Expectation
shouldSatisfy result predicate = result >>= (`H.shouldSatisfy` f) where
    f = machine False False predicate

-- Asserts that when the semantics have finished being evaulated, the machine
-- contains the given value.
shouldReturn :: (Eq a, Show a) => IO (Machine a) -> a -> H.Expectation
shouldReturn result expected = result `H.shouldReturn` (return expected)

-- Asserts that the variable environment contains the given tape symbol for the
-- variable name.
shouldReturnSym :: IO (Machine Config) -> VarPath -> TapeSymbol -> H.Expectation
shouldReturnSym r path sym = shouldSatisfy r predicate where
    predicate config = Config.getSym path config == Just sym

-- Asserts that the environment contains the given object for the
-- variable name.
shouldReturnObj :: IO (Machine Config) -> VarPath -> Object -> H.Expectation
shouldReturnObj r path obj = shouldSatisfy r predicate where
    predicate config = getObjCpy path config == Just obj

-- Asserts that the function environment contains the given function body for
-- the function name.
shouldReturnFunc :: IO (Machine Config) -> FuncName -> [FuncDeclArg] -> Stm -> H.Expectation
shouldReturnFunc r name args body = shouldSatisfy r predicate where
    predicate config = getFunc name config == Just (args, body)

-- Asserts that the environment contains the given struct.
shouldReturnStruct :: IO (Machine Config) -> StructName -> [VarName] -> H.Expectation
shouldReturnStruct r name vs = shouldSatisfy r predicate where
    predicate config = getStructMems name config == Just vs

-- Asserts that when the semantics have finished being evauluated, the position
-- of the read-write head is in the given position.
shouldBeAt :: IO (Machine Config) -> VarPath -> Pos -> H.Expectation
shouldBeAt r path p = shouldSatisfy r predicate where
    predicate c = pos (fromJust (getTapeCpy path c)) == p

-- Asserts that the tape has the string `str` at the start of the tape.
shouldRead :: IO (Machine Config) -> VarPath -> [TapeSymbol] -> H.Expectation
shouldRead r path syms = shouldSatisfy r predicate where
    predicate c = contents (fromJust (getTapeCpy path c)) == contents (T.fromString syms)

-- Asserts that the machine halted in the accepting state.
shouldAccept :: IO (Machine Config) -> H.Expectation
shouldAccept r = r >>= (`H.shouldBe` HaltA)

-- Asserts that the machine halted in the rejecting state.
shouldReject :: IO (Machine Config) -> H.Expectation
shouldReject r = r >>= (`H.shouldBe` HaltR)

-- Asserts that the machine outputted the given strings.
shouldOutput :: TestM (Machine Config) -> [String] -> H.Expectation
shouldOutput r expected = logTestM r `H.shouldBe` expected
