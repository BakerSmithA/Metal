module Syntax.Func where

import Syntax.Common
import qualified Syntax.Env as E
import Syntax.Identifier
import Syntax.Variable

-- Attempts to parse an identifier used to declare a new function. Does **not**
-- add the function to the environment if it does not exist. Fails if the
-- function already exists. EBNF:
--  FuncName : LowerChar (LowerChar | UpperChar | Digit)*
newFunc :: ParserM FuncName
newFunc = newId snakeId

-- Attempts to use a declared variable, but does **not** check for matching
-- types. If the variable does not exist then parsing fails. EBNF:
--  FuncName : LowerChar (LowerChar | UpperChar | Digit)*
refFunc :: ParserM (FuncName, [DataType])
refFunc = do
    (name, idType) <- refId snakeId
    case idType of
        PFunc argTypes -> return (name, argTypes)
        _              -> fail "Expected function"

-- Parses a function argument, the EBNF syntax of which is:
--  ArgName : LowerChar (LowerChar | UpperChar | Digit)*
newArg :: ParserM ArgName
newArg = newId snakeId

-- Parses an argument to a function, the EBNF of which is the same as a TypedVar.
funcDeclArg :: ParserM FuncDeclArg
funcDeclArg = do
    (name, argType) <- typedVar newArg
    putM name (PVar argType)
    return (FuncDeclArg name argType)

-- Parses argument names of a function declaration, the EBNF syntax of which is:
--  FuncDeclArgs  : FuncDeclArg (' ' TypedVar)* | ε
funcDeclArgs :: ParserM FuncDeclArgs
funcDeclArgs = funcDeclArg `sepBy` lWhitespace

-- Parses the arguments and body of a function.
funcArgsBody :: ParserM Stm -> ParserM (FuncDeclArgs, Stm)
funcArgsBody stm = do
    args <- funcDeclArgs
    body <- braces stm
    return (args, body)

-- Parses a function declaration, the EBNF syntax of which is:
--  FuncDecl : 'func' FuncName FuncDeclArgs '{' Stm '}'
funcDecl :: ParserM Stm -> ParserM Stm
funcDecl stm = do
    _ <- lTok "func"
    name <- newFunc
    (args, body) <- block (funcArgsBody stm)

    let argTypes = map (\(FuncDeclArg _ argType) -> argType) args
    putM name (PFunc argTypes)

    return (FuncDecl name args body)

-- Parses an argument to a function call, the EBNF syntax of which is:
--  FuncCallArg : DerivedValue | TapeLiteral
funcCallArg :: DataType -> ParserM FuncCallArg
funcCallArg expectedType = arg <* lWhitespace where
    arg = Derived <$> derivedSymbol expectedType
      <|> TapeLiteral <$> tapeLiteral

-- Parses the arguments supplied to a function call, the EBNF syntax of which is:
--  FuncCallArgs : FuncCallArg (',' FuncCallArg) | ε
funcCallArgs :: [DataType] -> ParserM FuncCallArgs
funcCallArgs expectedTypes = foldl combine (return []) parseArgs where
    combine acc arg = (++) <$> acc <*> (fmap (\x -> [x]) arg)
    parseArgs = zipWith (\x y -> x y) (repeat funcCallArg) expectedTypes

-- Parses a function call, the EBNF syntax of which is:
--  Call : FuncName FuncCallArgs
funcCall :: ParserM Stm
funcCall = do
    (name, expectedArgTypes) <- refFunc
    args <- funcCallArgs expectedArgTypes
    return (Call name args)