module State.Env where

import Syntax.Tree

-- A list of variable definitions which maps variable names to tape symbols.
type VarDefs = [(VarName, TapeSymbol)]

-- A function definitions which maps function names to function bodies.
type FuncDefs = [(FuncName, Stm)]

-- The final environment consists of both a variable and function definitions.
data Env = Env {
    vars  :: VarDefs
  , funcs :: FuncDefs
}

-- An empty environment containing no variable or function definitions.
initial :: Env
initial = Env [] []

-- Looks up a variable in an environment.
lookupVar :: VarName -> Env -> Maybe TapeSymbol
lookupVar name env = lookup name (vars env)

-- Looks up a function in an environment.
lookupFunc :: FuncName -> Env -> Maybe Stm
lookupFunc name env = lookup name (funcs env)

-- Adds a list of variable definitions to the environment.
addVars :: VarDefs -> Env -> Env
addVars defs env = env { vars = defs ++ (vars env) }

-- Adds a list of function definitions to the environment.
addFuncs :: FuncDefs -> Env -> Env
addFuncs defs env = env { funcs = defs ++ (funcs env) }

-- Adds a single variable to the environment.
addVar :: VarName -> TapeSymbol -> Env -> Env
addVar name sym = addVars [(name, sym)]

-- Adds a single function to the environment.
addFunc :: FuncName -> Stm -> Env -> Env
addFunc name body = addFuncs [(name, body)]
