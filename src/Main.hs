module Main where

import Syntax.Tree
import State.Config as Config
import State.Env as Env
import Semantics.Denotational

main :: IO ()
main = do
    let stm = (Comp (PrintStr "STR") Accept)
    return ()
